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

import CocoaLumberjackSwift
import Foundation
import InfomaniakCoreUI
import InfomaniakDI
import MailResources
import RealmSwift
import Sentry

// MARK: - Message

public extension MailboxManager {
    func messages(folder: Folder, isRetrying: Bool = false) async throws {
        guard !Task.isCancelled else { return }

        let realm = getRealm()
        let freshFolder = folder.fresh(using: realm)

        let previousCursor = freshFolder?.cursor
        var messagesUids: MessagesUids

        if previousCursor == nil {
            let messageUidsResult = try await apiFetcher.messagesUids(
                mailboxUuid: mailbox.uuid,
                folderId: folder.remoteId,
                paginationInfo: nil
            )
            messagesUids = MessagesUids(
                addedShortUids: messageUidsResult.messageShortUids,
                cursor: messageUidsResult.cursor
            )
        } else {
            let messageDeltaResult = try await apiFetcher.messagesDelta(
                mailboxUUid: mailbox.uuid,
                folderId: folder.remoteId,
                signature: previousCursor!
            )
            messagesUids = MessagesUids(
                addedShortUids: [],
                deletedUids: messageDeltaResult.deletedShortUids
                    .map { Constants.longUid(from: $0, folderId: folder.remoteId) },
                updated: messageDeltaResult.updated,
                cursor: messageDeltaResult.cursor,
                folderUnreadCount: messageDeltaResult.unreadCount
            )
        }

        try await handleMessagesUids(messageUids: messagesUids, folder: folder)

        guard !Task.isCancelled else { return }

        await backgroundRealm.execute { realm in
            guard let folder = folder.fresh(using: realm) else {
                self.logError(.missingFolder)
                return
            }
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
                folderId: folder.remoteId,
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
            try await catchLostOffsetMessageError(folder: folder, isRetrying: isRetrying) {
                while try await fetchOnePage(folder: folder, direction: .following) {
                    guard !Task.isCancelled else { return }
                }
            }
        }

        if folder.role == .inbox,
           let freshFolder = folder.fresh(using: getRealm()) {
            mailboxInfosManager.updateUnseen(unseenMessages: freshFolder.unreadCount, for: mailbox)
            Task {
                await NotificationsHelper.clearAlreadyReadNotifications()
                await NotificationsHelper.updateUnreadCountBadge()
            }
        }

        let realmPrevious = getRealm()
        guard let folderPrevious = folder.fresh(using: realmPrevious) else {
            logError(.missingFolder)
            return
        }
        var remainingOldMessagesToFetch = folderPrevious.remainingOldMessagesToFetch
        while remainingOldMessagesToFetch > 0 {
            guard !Task.isCancelled else { return }

            if try await !fetchOnePage(folder: folder, direction: .previous) {
                break
            }

            remainingOldMessagesToFetch -= Constants.pageSize
        }
    }

    private func catchLostOffsetMessageError(folder: Folder, isRetrying: Bool, block: () async throws -> Void) async throws {
        do {
            try await block()
        } catch let error as MailError where error == MailApiError.lostOffsetMessage {
            guard !isRetrying else {
                DDLogError("We couldn't rebuild folder history even after retrying from scratch")
                SentryDebug.failedResetingAfterBackoff(folder: folder)
                throw MailError.unknownError
            }

            DDLogWarn("resetHistoryInfo because of lostOffsetMessageError")
            SentryDebug.addResetingFolderBreadcrumb(folder: folder)

            await backgroundRealm.execute { realm in
                guard let folder = folder.fresh(using: realm) else {
                    self.logError(.missingFolder)
                    return
                }

                try? realm.write {
                    realm.delete(folder.messages)
                    realm.delete(folder.threads)
                    folder.lastUpdate = nil
                    folder.unreadCount = 0
                    folder.remainingOldMessagesToFetch = Constants.messageQuantityLimit
                    folder.isHistoryComplete = false
                    folder.cursor = nil
                }
            }
            try await messages(folder: folder, isRetrying: true)
        }
    }

    func messageUidsWithBackOff(folder: Folder,
                                direction: NewMessagesDirection? = nil,
                                backoffIndex: Int = 0) async throws -> MessageUidsResult {
        let backoffSequence = [1, 1, 2, 8, 34, 144]
        guard backoffIndex < backoffSequence.count else {
            throw MailError.lostOffsetMessage
        }

        SentryDebug.addBackoffBreadcrumb(folder: folder, index: backoffIndex)

        let realm = getRealm()
        var paginationInfo: PaginationInfo?

        let sortedMessages = realm.objects(Message.self).where { $0.folderId == folder.remoteId }
            .sorted {
                guard let firstMessageShortUid = $0.shortUid,
                      let secondMessageShortUid = $1.shortUid else {
                    SentryDebug.castToShortUidFailed(firstUid: $0.uid, secondUid: $1.uid)
                    return false
                }

                if direction == .following {
                    return firstMessageShortUid > secondMessageShortUid
                }
                return firstMessageShortUid < secondMessageShortUid
            }

        let backoffOffset = backoffSequence[backoffIndex] - 1
        let currentOffset = min(backoffOffset, sortedMessages.count - 1)

        // We already did one call and last call was already above sortedMessages.count so we stop wasting more calls
        if backoffIndex > 0 && backoffSequence[backoffIndex - 1] - 1 > sortedMessages.count - 1 {
            throw MailError.lostOffsetMessage
        }

        if currentOffset >= 0,
           let offset = sortedMessages[currentOffset].shortUid?.toString(),
           let direction {
            paginationInfo = PaginationInfo(offsetUid: offset, direction: direction)
        }

        do {
            let result = try await apiFetcher.messagesUids(
                mailboxUuid: mailbox.uuid,
                folderId: folder.remoteId,
                paginationInfo: paginationInfo
            )
            return result
        } catch let error as MailError where error == MailApiError.apiMessageNotFound {
            try await Task.sleep(nanoseconds: UInt64(0.5 * Double(NSEC_PER_SEC)))
            let result = try await messageUidsWithBackOff(
                folder: folder,
                direction: direction,
                backoffIndex: backoffIndex + 1
            )

            return result
        }
    }

    func fetchOnePage(folder: Folder, direction: NewMessagesDirection? = nil) async throws -> Bool {
        let messageUidsResult = try await messageUidsWithBackOff(folder: folder, direction: direction)

        let messagesUids = MessagesUids(
            addedShortUids: messageUidsResult.messageShortUids,
            cursor: messageUidsResult.cursor
        )

        try await handleMessagesUids(messageUids: messagesUids, folder: folder)

        switch direction {
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

    func markAsSeen(message: Message, seen: Bool = true) async throws {
        if seen {
            var messages = [message]
            messages.append(contentsOf: message.duplicates)
            try await markAsSeen(messages: messages, seen: seen)
        } else {
            try await markAsSeen(messages: [message], seen: seen)
        }
    }

    func move(messages: [Message], to folderRole: FolderRole) async throws -> UndoAction {
        guard let folder = getFolder(with: folderRole)?.freeze() else { throw MailError.folderNotFound }
        return try await move(messages: messages, to: folder)
    }

    func move(messages: [Message], to folder: Folder) async throws -> UndoAction {
        let response = try await apiFetcher.move(mailbox: mailbox, messages: messages, destinationId: folder.remoteId)
        try await refreshFolder(from: messages, additionalFolder: folder)
        return undoAction(for: response, and: messages)
    }

    func delete(messages: [Message]) async throws {
        try await apiFetcher.delete(mailbox: mailbox, messages: messages)
        try await refreshFolder(from: messages)
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
            folderId: folder.remoteId,
            messageUids: uniqueUids
        )

        let backgroundTracker = await ApplicationBackgroundTaskTracker(identifier: #function + UUID().uuidString)
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
        await backgroundTracker.end()
    }

    private func createThreads(messageByUids: MessageByUidsResult, folder: Folder, using realm: Realm) {
        var threadsToUpdate = Set<Thread>()
        try? realm.safeWrite {
            for message in messageByUids.messages {
                guard realm.object(ofType: Message.self, forPrimaryKey: message.uid) == nil else {
                    SentrySDK.capture(message: "Found already existing message") { scope in
                        scope.setContext(value: ["Message": ["uid": message.uid,
                                                             "messageId": message.messageId],
                                                 "Folder": ["id": message.folder?.remoteId,
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
                    let (updatedThreads, removedDuplicatedThreads) = createConversationThread(
                        message: message,
                        folder: folder,
                        using: realm
                    )
                    threadsToUpdate.subtract(removedDuplicatedThreads)
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
    ) -> (threadsToUpdate: Set<Thread>, removedDuplicatedThreads: Set<Thread>) {
        var threadsToUpdate = Set<Thread>()

        let existingThreads = Array(realm.objects(Thread.self)
            .where { $0.messageIds.containsAny(in: message.linkedUids) })

        // Some Messages don't have references to all previous Messages of the Thread (ex: these from the iOS Mail app).
        // Because we are missing the links between Messages, it will create multiple Threads for the same Folder.
        // Hence, we need to find these duplicates.
        let isThereDuplicatedThreads = isThereDuplicatedThreads(
            realm: realm,
            messageIds: message.linkedUids,
            threadCount: existingThreads.count
        )

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
                    thread.addMessageIfNeeded(newMessage: existingMessage.fresh(using: realm) ?? existingMessage)
                }
            }

            threadsToUpdate.insert(thread)
        }

        // Now that all other existing Threads are updated, we need to remove the duplicated Threads.
        if isThereDuplicatedThreads {
            return removeDuplicatedThreads(messageIds: message.linkedUids, threadsToUpdate: threadsToUpdate, using: realm)
        } else {
            return (threadsToUpdate, Set<Thread>())
        }
    }

    private func isThereDuplicatedThreads(realm: Realm, messageIds: MutableSet<String>, threadCount: Int) -> Bool {
        let foldersCount = realm.objects(Thread.self).where { $0.messageIds.containsAny(in: messageIds) }
            .distinct(by: [\Thread.folderId]).count
        return foldersCount != threadCount
    }

    private func removeDuplicatedThreads(
        messageIds: MutableSet<String>,
        threadsToUpdate: Set<Thread>,
        using realm: Realm
    ) -> (threadsToUpdate: Set<Thread>, removedDuplicatedThreads: Set<Thread>) {
        var threadsToUpdate = threadsToUpdate
        var deletedThreads = Set<Thread>()
        // Create a map with all duplicated Threads of the same Thread in a list.
        let threads = realm.objects(Thread.self).where { $0.messageIds.containsAny(in: messageIds) }
        let map: [String: [Thread]] = Dictionary(grouping: threads) { $0.folderId }

        for value in map.values {
            for (index, thread) in value.enumerated() where index > 0 {
                // We want to keep only 1 duplicated Thread, so we skip the 1st one. (He's the chosen one!)
                threadsToUpdate.remove(thread)
                deletedThreads.insert(thread)
                realm.delete(thread)
            }
        }

        return (threadsToUpdate, deletedThreads)
    }

    private func createSingleMessageThread(message: Message, folder: Folder) -> Thread {
        let thread = message.toThread().detached()
        folder.threads.insert(thread)
        return thread
    }

    private func createNewThreadIfRequired(for message: Message, folder: Folder, existingThreads: [Thread]) -> Thread? {
        guard folder.role != .draft else {
            let thread = message.toThread().detached()
            folder.threads.insert(thread)
            return thread
        }
        guard !existingThreads.contains(where: { $0.folder == folder }) else {
            logError(.missingFolder)
            return nil
        }

        let thread = message.toThread().detached()
        folder.threads.insert(thread)

        let refMessages = existingThreads.flatMap(\.messages).toSet()
        addPreviousMessagesTo(newThread: thread, from: refMessages)

        return thread
    }

    private func addPreviousMessagesTo(newThread: Thread, from refMessages: Set<Message>) {
        for message in refMessages {
            newThread.messageIds.insert(objectsIn: message.linkedUids)
            newThread.addMessageIfNeeded(newMessage: message)
        }
    }

    private func updateMessages(updates: [MessageFlags], folder: Folder) async {
        guard !Task.isCancelled else { return }

        let backgroundTracker = await ApplicationBackgroundTaskTracker(identifier: #function + UUID().uuidString)
        await backgroundRealm.execute { realm in
            var threadsToUpdate = Set<Thread>()
            try? realm.safeWrite {
                for update in updates {
                    let uid = Constants.longUid(from: String(update.shortUid), folderId: folder.remoteId)
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
        await backgroundTracker.end()
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

    func markAsSeen(messages: [Message], seen: Bool) async throws {
        if seen {
            try await apiFetcher.markAsSeen(mailbox: mailbox, messages: messages)
        } else {
            try await apiFetcher.markAsUnseen(mailbox: mailbox, messages: messages)
        }
        try await refreshFolder(from: messages)

        // TODO: Remove after fix
        SentryDebug.listIncoherentMessageUpdate(messages: messages, actualSeen: seen)
    }

    /// Set starred the given messages.
    /// - Important: This methods stars only the messages you passes, no processing is done to add duplicates or remove drafts
    func star(messages: [Message], starred: Bool) async throws {
        if starred {
            _ = try await star(messages: messages)
        } else {
            _ = try await unstar(messages: messages)
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

    private func undoAction(for cancellableResponse: UndoResponse, and messages: [Message]) -> UndoAction {
        let undoBlock = {
            try await self.refreshFolder(from: messages)
        }
        return UndoAction(undo: cancellableResponse, undoBlock: undoBlock)
    }
}
