/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import InfomaniakCoreUI
import MailResources
import RealmSwift
import Sentry

// MARK: - Message

public extension MailboxManager {
    func messages(folder: Folder) async throws {
        guard !Task.isCancelled else { return }

        let realm = getRealm()
        let freshFolder = folder.fresh(using: realm)

        let previousCursor = freshFolder?.cursor
        var messagesUids: MessagesUids

        if previousCursor == nil {
            let messageUidsResult = try await apiFetcher.messagesUids(
                mailboxUuid: mailbox.uuid,
                folderId: folder.id,
                paginationInfo: nil
            )
            messagesUids = MessagesUids(
                addedShortUids: messageUidsResult.messageShortUids,
                cursor: messageUidsResult.cursor
            )
        } else {
            let messageDeltaResult = try await apiFetcher.messagesDelta(
                mailboxUUid: mailbox.uuid,
                folderId: folder.id,
                signature: previousCursor!
            )
            messagesUids = MessagesUids(
                addedShortUids: [],
                deletedUids: messageDeltaResult.deletedShortUids
                    .map { Constants.longUid(from: $0, folderId: folder.id) },
                updated: messageDeltaResult.updated,
                cursor: messageDeltaResult.cursor,
                folderUnreadCount: messageDeltaResult.unreadCount
            )
        }

        try await handleMessagesUids(messageUids: messagesUids, folder: folder)

        guard !Task.isCancelled else { return }

        await backgroundRealm.execute { realm in
            guard let folder = folder.fresh(using: realm) else { return }
            try? realm.safeWrite {
                if previousCursor == nil && messagesUids.addedShortUids.count < Constants.pageSize {
                    folder.completeHistoryInfo()
                }
                if let newUnreadCount = messagesUids.folderUnreadCount {
                    folder.remoteUnreadCount = newUnreadCount
                }
                folder.computeUnreadCount()
                folder.cursor = messagesUids.cursor
                folder.lastUpdate = Date()
            }

            SentryDebug.searchForOrphanMessages(
                folderId: folder.id,
                using: realm,
                previousCursor: previousCursor,
                newCursor: messagesUids.cursor
            )
            SentryDebug.searchForOrphanThreads(
                using: realm,
                previousCursor: previousCursor,
                newCursor: messagesUids.cursor
            )
        }

        if previousCursor != nil {
            while try await fetchOnePage(folder: folder, direction: .following) {
                guard !Task.isCancelled else { return }
            }
        }

        if folder.role == .inbox,
           let freshFolder = folder.fresh(using: getRealm()) {
            MailboxInfosManager.instance.updateUnseen(unseenMessages: freshFolder.unreadCount, for: mailbox)
        }

        let realmPrevious = getRealm()
        if let folderPrevious = folder.fresh(using: realmPrevious) {
            var remainingOldMessagesToFetch = folderPrevious.remainingOldMessagesToFetch
            while remainingOldMessagesToFetch > 0 {
                guard !Task.isCancelled else { return }

                if await try !fetchOnePage(folder: folder, direction: .previous) {
                    break
                }

                remainingOldMessagesToFetch -= Constants.pageSize
            }
        }
    }

    func fetchOnePage(folder: Folder, direction: NewMessagesDirection? = nil) async throws -> Bool {
        let realm = getRealm()
        var paginationInfo: PaginationInfo?

        if let offset = realm.objects(Message.self).where({ $0.folderId == folder.id })
            .sorted(by: {
                if direction == .following {
                    return $0.shortUid! > $1.shortUid!
                }
                return $0.shortUid! < $1.shortUid!
            }).first?.shortUid?.toString(),
            let direction {
            paginationInfo = PaginationInfo(offsetUid: offset, direction: direction)
        }

        let messageUidsResult = try await apiFetcher.messagesUids(
            mailboxUuid: mailbox.uuid,
            folderId: folder.id,
            paginationInfo: paginationInfo
        )
        let messagesUids = MessagesUids(
            addedShortUids: messageUidsResult.messageShortUids,
            cursor: messageUidsResult.cursor
        )

        try await handleMessagesUids(messageUids: messagesUids, folder: folder)

        switch paginationInfo?.direction {
        case .previous:
            return await backgroundRealm.execute { realm in
                let freshFolder = folder.fresh(using: realm)
                if messagesUids.addedShortUids.count < Constants.pageSize || messagesUids.addedShortUids.contains("1") {
                    try? realm.safeWrite {
                        freshFolder?.completeHistoryInfo()
                    }
                    return false
                } else {
                    try? realm.safeWrite {
                        freshFolder?.remainingOldMessagesToFetch -= Constants.pageSize
                    }
                    return true
                }
            }
        case .following:
            break
        case .none:
            await backgroundRealm.execute { realm in
                let freshFolder = folder.fresh(using: realm)
                try? realm.safeWrite {
                    freshFolder?.resetHistoryInfo()

                    if messagesUids.addedShortUids.count < Constants.pageSize {
                        freshFolder?.completeHistoryInfo()
                    }
                }
            }
        }
        return messagesUids.addedShortUids.count == Constants.pageSize
    }

    func message(message: Message) async throws {
        // Get from API
        let completedMessage = try await apiFetcher.message(message: message)
        completedMessage.fullyDownloaded = true

        await backgroundRealm.execute { realm in
            // Update message in Realm
            try? realm.safeWrite {
                realm.add(completedMessage, update: .modified)
            }
        }
    }

    func attachmentData(attachment: Attachment) async throws -> Data {
        let data = try await apiFetcher.attachment(attachment: attachment)

        let safeAttachment = ThreadSafeReference(to: attachment)
        await backgroundRealm.execute { realm in
            if let liveAttachment = realm.resolve(safeAttachment) {
                try? realm.safeWrite {
                    liveAttachment.saved = true
                }
            }
        }

        return data
    }

    func saveAttachmentLocally(attachment: Attachment) async {
        do {
            let data = try await attachmentData(attachment: attachment)
            if let url = attachment.localUrl {
                let parentFolder = url.deletingLastPathComponent()
                if !FileManager.default.fileExists(atPath: parentFolder.path) {
                    try FileManager.default.createDirectory(at: parentFolder, withIntermediateDirectories: true)
                }
                try data.write(to: url)
            }
        } catch {
            // Handle error
            print("Failed to save attachment: \(error)")
        }
    }

    func moveOrDelete(messages: [Message]) async throws {
        let messagesGroupedByFolderId = Dictionary(grouping: messages, by: \.folderId)

        await withThrowingTaskGroup(of: Void.self) { group in
            for messagesInSameFolder in messagesGroupedByFolderId.values {
                group.addTask {
                    try await self.moveOrDeleteMessagesInSameFolder(messages: messagesInSameFolder)
                }
            }
        }
    }

    func markAsSeen(message: Message, seen: Bool = true) async throws {
        if seen {
            var messages = [message]
            messages.append(contentsOf: message.duplicates)
            try await markAsSeen(messages: messages, seen: seen)
        } else {
            try await markAsSeen(messages: [message], seen: seen)
        }
    }

    func move(messages: [Message], to folderRole: FolderRole) async throws -> UndoRedoAction {
        guard let folder = getFolder(with: folderRole)?.freeze() else { throw MailError.folderNotFound }
        return try await move(messages: messages, to: folder)
    }

    func move(messages: [Message], to folder: Folder) async throws -> UndoRedoAction {
        let response = try await apiFetcher.move(mailbox: mailbox, messages: messages, destinationId: folder._id)
        try await refreshFolder(from: messages, additionalFolder: folder)
        return undoRedoAction(for: response, and: messages)
    }

    func delete(messages: [Message]) async throws {
        _ = try await apiFetcher.delete(mailbox: mailbox, messages: messages)
        try await refreshFolder(from: messages)
    }

    func toggleStar(messages: [Message]) async throws {
        if messages.contains(where: { !$0.flagged }) {
            let messagesToStar = messages + messages.flatMap(\.duplicates)
            _ = try await star(messages: messagesToStar)
        } else {
            let messagesToUnstar = messages
                .compactMap { $0.originalThread?.messages.where { $0.isDraft == false } }
                .flatMap { $0 + $0.flatMap(\.duplicates) }
            _ = try await unstar(messages: messagesToUnstar)
        }
    }

    // MARK: Private

    private func getUniqueUids(folder: Folder, remoteUids: [String]) -> [String] {
        let localUids = Set(folder.threads.map { Constants.shortUid(from: $0.uid) })
        let remoteUidsSet = Set(remoteUids)
        var uniqueUids: Set<String> = Set()
        if localUids.isEmpty {
            uniqueUids = remoteUidsSet
        } else {
            uniqueUids = remoteUidsSet.subtracting(localUids)
        }
        return uniqueUids.toArray()
    }

    private func handleMessagesUids(messageUids: MessagesUids, folder: Folder) async throws {
        let startDate = Date(timeIntervalSinceNow: -5 * 60)
        let ignoredIds = folder.fresh(using: getRealm())?.threads
            .where { $0.date > startDate }
            .map(\.uid) ?? []
        await deleteMessages(uids: messageUids.deletedUids)
        var shouldIgnoreNextEvents = SentryDebug.captureWrongDate(
            step: "After delete",
            startDate: startDate,
            folder: folder,
            alreadyWrongIds: ignoredIds,
            realm: getRealm()
        )
        await updateMessages(updates: messageUids.updated, folder: folder)
        if !shouldIgnoreNextEvents {
            shouldIgnoreNextEvents = SentryDebug.captureWrongDate(
                step: "After updateMessages",
                startDate: startDate,
                folder: folder,
                alreadyWrongIds: ignoredIds,
                realm: getRealm()
            )
        }
        try await addMessages(shortUids: messageUids.addedShortUids, folder: folder, newCursor: messageUids.cursor)
        if !shouldIgnoreNextEvents {
            _ = SentryDebug.captureWrongDate(
                step: "After addMessages",
                startDate: startDate,
                folder: folder,
                alreadyWrongIds: ignoredIds,
                realm: getRealm()
            )
        }
    }

    private func addMessages(shortUids: [String], folder: Folder, newCursor: String?) async throws {
        guard !shortUids.isEmpty && !Task.isCancelled else { return }

        let uniqueUids: [String] = getUniqueUids(folder: folder, remoteUids: shortUids)
        let messageByUidsResult = try await apiFetcher.messagesByUids(
            mailboxUuid: mailbox.uuid,
            folderId: folder.id,
            messageUids: uniqueUids
        )

        await backgroundRealm.execute { [self] realm in
            if let folder = folder.fresh(using: realm) {
                createThreads(messageByUids: messageByUidsResult, folder: folder, using: realm)
            }
            SentryDebug.sendMissingMessagesSentry(
                sentUids: uniqueUids,
                receivedMessages: messageByUidsResult.messages,
                folder: folder,
                newCursor: newCursor
            )
        }
    }

    private func createThreads(messageByUids: MessageByUidsResult, folder: Folder, using realm: Realm) {
        var threadsToUpdate = Set<Thread>()
        try? realm.safeWrite {
            for message in messageByUids.messages {
                guard realm.object(ofType: Message.self, forPrimaryKey: message.uid) == nil else {
                    SentrySDK.capture(message: "Found already existing message") { scope in
                        scope.setContext(value: ["Message": ["uid": message.uid,
                                                             "messageId": message.messageId],
                                                 "Folder": ["id": message.folder?._id,
                                                            "name": message.folder?.name,
                                                            "cursor": message.folder?.cursor]],
                                         key: "Message context")
                    }
                    continue
                }
                message.inTrash = folder.role == .trash
                message.computeReference()

                let isThreadMode = UserDefaults.shared.threadMode == .conversation
                if isThreadMode {
                    let updatedThreads = createConversationThread(message: message, folder: folder, using: realm)
                    threadsToUpdate.formUnion(updatedThreads)
                } else {
                    let createdThread = createSingleMessageThread(message: message, folder: folder)
                    threadsToUpdate.insert(createdThread)
                }

                if let message = realm.objects(Message.self).first(where: { $0.uid == message.uid }) {
                    folder.messages.insert(message)
                }
            }
            self.updateThreads(threads: threadsToUpdate, realm: realm)
        }
    }

    private func createConversationThread(
        message: Message,
        folder: Folder,
        using realm: Realm
    ) -> Set<Thread> {
        var threadsToUpdate = Set<Thread>()

        let existingThreads = Array(realm.objects(Thread.self)
            .where { $0.messageIds.containsAny(in: message.linkedUids) /* && $0.isConversationThread == true */ })

        if let newThread = createNewThreadIfRequired(
            for: message,
            folder: folder,
            existingThreads: existingThreads
        ) {
            threadsToUpdate.insert(newThread)
        }

        var allExistingMessages = Set(existingThreads.flatMap(\.messages))
        allExistingMessages.insert(message)

        for thread in existingThreads {
            for existingMessage in allExistingMessages {
                if !thread.messages.map(\.uid).contains(existingMessage.uid) {
                    thread.addMessageIfNeeded(newMessage: message.fresh(using: realm) ?? message)
                }
            }

            threadsToUpdate.insert(thread)
        }
        return threadsToUpdate
    }

    private func createSingleMessageThread(message: Message, folder: Folder) -> Thread {
        let thread = message.toThread().detached()
        folder.threads.insert(thread)
        return thread
    }

    private func createNewThreadIfRequired(for message: Message, folder: Folder, existingThreads: [Thread]) -> Thread? {
        guard !existingThreads.contains(where: { $0.folder == folder }) else { return nil }

        let thread = message.toThread().detached()
        folder.threads.insert(thread)

        if let refThread = existingThreads.first(where: { $0.folder?.role != .draft && $0.folder?.role != .trash }) {
            addPreviousMessagesTo(newThread: thread, from: refThread)
        } else {
            for existingThread in existingThreads {
                addPreviousMessagesTo(newThread: thread, from: existingThread)
            }
        }
        return thread
    }

    private func addPreviousMessagesTo(newThread: Thread, from existingThread: Thread) {
        newThread.messageIds.insert(objectsIn: existingThread.messageIds)
        for message in existingThread.messages {
            newThread.addMessageIfNeeded(newMessage: message)
        }
    }

    private func updateMessages(updates: [MessageFlags], folder: Folder) async {
        guard !Task.isCancelled else { return }

        await backgroundRealm.execute { realm in
            var threadsToUpdate = Set<Thread>()
            try? realm.safeWrite {
                for update in updates {
                    let uid = Constants.longUid(from: String(update.shortUid), folderId: folder.id)
                    if let message = realm.object(ofType: Message.self, forPrimaryKey: uid) {
                        message.answered = update.answered
                        message.flagged = update.isFavorite
                        message.forwarded = update.forwarded
                        message.scheduled = update.scheduled
                        message.seen = update.seen

                        for parent in message.threads {
                            threadsToUpdate.insert(parent)
                        }
                    }
                }
                self.updateThreads(threads: threadsToUpdate, realm: realm)
            }
        }
    }

    private func updateThreads(threads: Set<Thread>, realm: Realm) {
        let folders = Set(threads.compactMap(\.folder))
        for thread in threads {
            do {
                try thread.recomputeOrFail()
            } catch {
                SentryDebug.threadHasNilLastMessageFromFolderDate(thread: thread)
                realm.delete(thread)
            }
        }
        for folder in folders {
            folder.computeUnreadCount()
        }
    }

    private func moveOrDeleteMessagesInSameFolder(messages: [Message]) async throws {
        let messagesToMoveOrDelete = messages + messages.flatMap(\.duplicates)

        let firstMessageFolderRole = messages.first?.folder?.role
        if firstMessageFolderRole == .trash
            || firstMessageFolderRole == .spam
            || firstMessageFolderRole == .draft {
            try await delete(messages: messagesToMoveOrDelete)
            async let _ = snackbarPresenter.show(message: deletionSnackbarMessage(for: messages, permanentlyDelete: true))
        } else {
            let undoRedoAction = try await move(messages: messagesToMoveOrDelete, to: .trash)
            async let _ = IKSnackBar.showCancelableSnackBar(
                message: deletionSnackbarMessage(for: messages, permanentlyDelete: false),
                cancelSuccessMessage: MailResourcesStrings.Localizable.snackbarMoveCancelled,
                undoRedoAction: undoRedoAction,
                mailboxManager: self
            )
        }
    }

    private func deletionSnackbarMessage(for messages: [Message], permanentlyDelete: Bool) -> String {
        if let firstMessageThreadMessagesCount = messages.first?.originalThread?.messages.count,
           messages.count == 1 && firstMessageThreadMessagesCount > 1 {
            return permanentlyDelete ?
                MailResourcesStrings.Localizable.snackbarMessageDeletedPermanently :
                MailResourcesStrings.Localizable.snackbarMessageMoved(FolderRole.trash.localizedName)
        } else {
            let uniqueThreadCount = Set(messages.compactMap(\.originalThread?.uid)).count
            if permanentlyDelete {
                return MailResourcesStrings.Localizable.snackbarThreadDeletedPermanently(uniqueThreadCount)
            } else if uniqueThreadCount == 1 {
                return MailResourcesStrings.Localizable.snackbarThreadMoved(FolderRole.trash.localizedName)
            } else {
                return MailResourcesStrings.Localizable.snackbarThreadsMoved(FolderRole.trash.localizedName)
            }
        }
    }

    internal func markAsSeen(messages: [Message], seen: Bool) async throws {
        if seen {
            _ = try await apiFetcher.markAsSeen(mailbox: mailbox, messages: messages)
        } else {
            _ = try await apiFetcher.markAsUnseen(mailbox: mailbox, messages: messages)
        }
        try await refreshFolder(from: messages)

        // TODO: Remove after fix
        Task {
            for message in messages {
                if let liveMessage = message.thaw(),
                   liveMessage.seen != seen {
                    SentrySDK.capture(message: "Found incoherent message update") { scope in
                        scope.setContext(value: ["Message": ["uid": message.uid,
                                                             "messageId": message.messageId,
                                                             "date": message.date,
                                                             "seen": message.seen,
                                                             "duplicates": message.duplicates.compactMap(\.messageId),
                                                             "references": message.references],
                                                 "Seen": ["Expected": seen, "Actual": liveMessage.seen],
                                                 "Folder": ["id": message.folder?._id,
                                                            "name": message.folder?.name,
                                                            "last update": message.folder?.lastUpdate,
                                                            "cursor": message.folder?.cursor]],
                                         key: "Message context")
                    }
                }
            }
        }
    }

    private func star(messages: [Message]) async throws -> MessageActionResult {
        let response = try await apiFetcher.star(mailbox: mailbox, messages: messages)
        try await refreshFolder(from: messages)
        return response
    }

    private func unstar(messages: [Message]) async throws -> MessageActionResult {
        let response = try await apiFetcher.unstar(mailbox: mailbox, messages: messages)
        try await refreshFolder(from: messages)
        return response
    }

    private func undoRedoAction(for cancellableResponse: UndoResponse, and messages: [Message]) -> UndoRedoAction {
        let redoAction = {
            try await self.refreshFolder(from: messages)
        }
        return UndoRedoAction(undo: cancellableResponse, redo: redoAction)
    }
}
