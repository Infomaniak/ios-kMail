/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import CocoaLumberjackSwift
import Foundation
import InfomaniakCore
import InfomaniakCoreDB
import InfomaniakCoreUI
import RealmSwift
import Sentry

// MARK: - Thread

public extension MailboxManager {
    /// Fetch messages for given folder
    /// Then fetch messages for `inbox`, `sent` and `draft` folder if needed
    /// - Parameters:
    ///   - folder: Folder to fetch messages from
    ///   - fetchCurrentFolderCompleted: Completion once the messages have been fetched
    func threads(@EnsureFrozen folder: Folder, fetchCurrentFolderCompleted: (() -> Void) = {}) async throws {
        try await messages(folder: folder)
        fetchCurrentFolderCompleted()

        var roles: [FolderRole] {
            switch folder.role {
            case .inbox:
                return [.sent, .draft]
            case .sent:
                return [.inbox, .draft]
            case .draft:
                return [.inbox, .sent]
            default:
                return []
            }
        }

        for folderRole in roles {
            guard !Task.isCancelled else { break }
            if let realFolder = getFolder(with: folderRole) {
                try await messages(folder: realFolder.freezeIfNeeded())
            }
        }
    }

    /// Fetch messages for a given folder
    /// - Parameters:
    ///   - folder: Folder to fetch
    ///   - isRetrying: is function called from a retry ?
    func messages(folder: Folder, isRetrying: Bool = false) async throws {
        guard !Task.isCancelled else { return }

        let liveFolder = folder.fresh(transactionable: self)
        if let liveFolder, liveFolder.messages.isEmpty {
            try? writeTransaction { writableRealm in
                let freshFolder = folder.fresh(using: writableRealm)
                freshFolder?.resetFolder()
            }
        }

        let previousCursor = liveFolder?.cursor
        var messagesUids: MessagesUids

        if previousCursor == nil {
            messagesUids = try await fetchOldMessagesUids(folder: folder)
        } else {
            /// Get delta from last cursor
            let messageDeltaResult = try await apiFetcher.messagesDelta(
                mailboxUUid: mailbox.uuid,
                folderId: folder.remoteId,
                signature: previousCursor!
            )
            /// WARNING:
            /// We're not adding addedShortUids because newMessage will be fetched later in the function
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

        try? writeTransaction { writableRealm in
            guard let folder = folder.fresh(using: writableRealm) else {
                self.logError(.missingFolder)
                return
            }

            if let newUnreadCount = messagesUids.folderUnreadCount {
                folder.remoteUnreadCount = newUnreadCount
            }
            folder.computeUnreadCount()
            folder.cursor = messagesUids.cursor
            folder.lastUpdate = Date()

            SentryDebug.searchForOrphanMessages(
                folderId: folder.remoteId,
                using: writableRealm,
                previousCursor: previousCursor,
                newCursor: messagesUids.cursor
            )
            SentryDebug.searchForOrphanThreads(
                using: writableRealm,
                previousCursor: previousCursor,
                newCursor: messagesUids.cursor
            )

            self.deleteOrphanMessagesAndThreads(writableRealm: writableRealm, folderId: folder.remoteId)
        }

        if previousCursor != nil {
            /// We will now fetch new messages
            try await catchLostOffsetMessageError(folder: folder, isRetrying: isRetrying) {
                while try await fetchOneNewPage(folder: folder) {
                    guard !Task.isCancelled else { return }
                }
            }
        }

        if folder.role == .inbox,
           let freshFolder = folder.fresh(transactionable: self) {
            let unreadCount = freshFolder.unreadCount
            Task {
                await mailboxInfosManager.updateUnseen(unseenMessages: unreadCount, for: mailbox)
                await NotificationsHelper.clearAlreadyReadNotifications()
                await NotificationsHelper.updateUnreadCountBadge()
            }
        }

        guard let folderPrevious = folder.fresh(transactionable: self) else {
            logError(.missingFolder)
            return
        }

        /// Fetch old messages until folder history is completed
        var messagesToFetch = min(
            folderPrevious.remainingOldMessagesToFetch,
            folderPrevious.oldMessagesUidsToFetch.count
        )
        while messagesToFetch > 0 {
            guard !Task.isCancelled else { return }

            try await fetchOneOldPage(folder: folder)

            messagesToFetch -= Constants.pageSize
        }
    }

    /// This function get all the messages uids from the chosen folder
    private func fetchOldMessagesUids(folder: Folder) async throws -> MessagesUids {
        /// Get ALL uids
        let messageUidsResult = try await apiFetcher.messagesUids(
            mailboxUuid: mailbox.uuid,
            folderId: folder.remoteId,
            paginationInfo: nil,
            shouldGetAll: true
        )

        try? writeTransaction { writableRealm in
            guard let folder = folder.fresh(using: writableRealm) else {
                self.logError(.missingFolder)
                return
            }

            folder.oldMessagesUidsToFetch = messageUidsResult.messageShortUids.toRealmList()
            folder.cursor = messageUidsResult.cursor
        }

        return MessagesUids(
            addedShortUids: [],
            cursor: messageUidsResult.cursor
        )
    }

    /// This function will try to get following page of MessagesUids of a folder.
    /// It will try different offset in case the offset uid used doesn't exist anymore.
    /// - Parameters:
    ///   - folder: Given folder
    ///   - direction: Following or previous page to get
    ///   - backoffIndex: index used in case the offset of the last call doesn't exist
    /// - Returns: MessageUidsResult
    func messageUidsWithBackOff(folder: Folder, backoffIndex: Int = 0) async throws -> MessageUidsResult {
        let backoffSequence = [1, 1, 2, 8, 34, 144]
        guard backoffIndex < backoffSequence.count else {
            throw MailError.lostOffsetMessage
        }

        SentryDebug.addBackoffBreadcrumb(folder: folder, index: backoffIndex)

        var paginationInfo: PaginationInfo?
        let sortedMessages = fetchResults(ofType: Message.self) { partial in
            partial.where { $0.folderId == folder.remoteId && !$0.fromSearch }
        }.sorted {
            guard let firstMessageShortUid = $0.shortUid,
                  let secondMessageShortUid = $1.shortUid else {
                SentryDebug.castToShortUidFailed(firstUid: $0.uid, secondUid: $1.uid)
                return false
            }

            return firstMessageShortUid > secondMessageShortUid
        }

        let backoffOffset = backoffSequence[backoffIndex] - 1
        let currentOffset = min(backoffOffset, sortedMessages.count - 1)

        // We already did one call and last call was already above sortedMessages.count so we stop wasting more calls
        if backoffIndex > 0 && backoffSequence[backoffIndex - 1] - 1 > sortedMessages.count - 1 {
            throw MailError.lostOffsetMessage
        }

        if currentOffset >= 0,
           let offset = sortedMessages[currentOffset].shortUid?.toString() {
            paginationInfo = PaginationInfo(offsetUid: offset, direction: .following)
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
            let result = try await messageUidsWithBackOff(folder: folder, backoffIndex: backoffIndex + 1)

            return result
        }
    }

    /// Following page
    /// - Parameters:
    ///   - folder: Given folder
    ///   - direction: Following or previous page to fetch
    /// - Returns: Returns if there are other pages to fetch
    func fetchOneNewPage(folder: Folder) async throws -> Bool {
        let messageUidsResult = try await messageUidsWithBackOff(folder: folder)

        let messagesUids = MessagesUids(
            addedShortUids: messageUidsResult.messageShortUids,
            cursor: messageUidsResult.cursor
        )

        try await handleMessagesUids(messageUids: messagesUids, folder: folder)
        return messagesUids.addedShortUids.count == Constants.pageSize
    }

    /// Previous page
    /// - Parameters:
    ///   - folder: Given folder
    ///   - direction: Following or previous page to fetch
    /// - Returns: Returns if there are other pages to fetch
    func fetchOneOldPage(folder: Folder) async throws {
        let nextUids: [String] = Array(folder.oldMessagesUidsToFetch[0 ..< Constants.pageSize])

        if !nextUids.isEmpty {
            let messagesUids = MessagesUids(
                addedShortUids: nextUids,
                cursor: folder.cursor ?? ""
            )

            try await handleMessagesUids(messageUids: messagesUids, folder: folder)
        }

        try? writeTransaction { writableRealm in
            let freshFolder = folder.fresh(using: writableRealm)
            freshFolder?.oldMessagesUidsToFetch.removeSubrange(0 ..< Constants.pageSize)
            freshFolder?.remainingOldMessagesToFetch -= Constants.pageSize
        }
    }

    // MARK: - Handle MessagesUids

    /// Handle MessagesUids
    /// Will delete, update and add messages from uids
    /// - Parameters:
    ///   - messageUids: Given MessagesUids
    ///   - folder: Given folder
    private func handleMessagesUids(messageUids: MessagesUids, folder: Folder) async throws {
        let startDate = Date(timeIntervalSinceNow: -5 * 60)
        let ignoredIds = folder.fresh(transactionable: self)?.threads
            .where { $0.date > startDate }
            .map(\.uid) ?? []
        await deleteMessages(uids: messageUids.deletedUids)
        var shouldIgnoreNextEvents = SentryDebug.captureWrongDate(
            step: "After delete",
            startDate: startDate,
            folder: folder,
            alreadyWrongIds: ignoredIds,
            transactionable: self
        )
        await updateMessages(updates: messageUids.updated, folder: folder)
        if !shouldIgnoreNextEvents {
            shouldIgnoreNextEvents = SentryDebug.captureWrongDate(
                step: "After updateMessages",
                startDate: startDate,
                folder: folder,
                alreadyWrongIds: ignoredIds,
                transactionable: self
            )
        }
        try await addMessages(shortUids: messageUids.addedShortUids, folder: folder, newCursor: messageUids.cursor)
        if !shouldIgnoreNextEvents {
            _ = SentryDebug.captureWrongDate(
                step: "After addMessages",
                startDate: startDate,
                folder: folder,
                alreadyWrongIds: ignoredIds,
                transactionable: self
            )
        }
    }

    private func deleteMessages(uids: [String]) async {
        guard !uids.isEmpty,
              !Task.isCancelled else {
            return
        }

        // Making sure the system will not terminate the app between batches
        let expiringActivity = ExpiringActivity()
        expiringActivity.start()

        let batchSize = 100
        for index in stride(from: 0, to: uids.count, by: batchSize) {
            try? writeTransaction { writableRealm in
                let uidsBatch = Array(uids[index ..< min(index + batchSize, uids.count)])

                let messagesToDelete = writableRealm.objects(Message.self).where { $0.uid.in(uidsBatch) }
                var threadsToUpdate = Set<Thread>()
                var threadsToDelete = Set<Thread>()
                var draftsToDelete = Set<Draft>()

                for message in messagesToDelete {
                    if let draft = self.draft(messageUid: message.uid, using: writableRealm) {
                        draftsToDelete.insert(draft)
                    }
                    for parent in message.threads {
                        threadsToUpdate.insert(parent)
                    }
                }

                let foldersToUpdate = Set(threadsToUpdate.compactMap(\.folder))

                for draft in draftsToDelete {
                    if draft.action == nil {
                        writableRealm.delete(draft)
                    } else {
                        draft.remoteUUID = ""
                    }
                }

                writableRealm.delete(messagesToDelete)
                for thread in threadsToUpdate where !thread.isInvalidated {
                    if thread.messageInFolderCount == 0 {
                        threadsToDelete.insert(thread)
                    } else {
                        do {
                            try thread.recomputeOrFail()
                        } catch {
                            threadsToDelete.insert(thread)
                            SentryDebug.threadHasNilLastMessageFromFolderDate(thread: thread)
                        }
                    }
                }
                writableRealm.delete(threadsToDelete)
                for updateFolder in foldersToUpdate {
                    updateFolder.computeUnreadCount()
                }
            }
        }

        expiringActivity.endAll()
    }

    private func updateMessages(updates: [MessageFlags], folder: Folder) async {
        guard !Task.isCancelled else { return }

        try? writeTransaction { writableRealm in
            var threadsToUpdate = Set<Thread>()
            for update in updates {
                let uid = Constants.longUid(from: String(update.shortUid), folderId: folder.remoteId)
                if let message = writableRealm.object(ofType: Message.self, forPrimaryKey: uid) {
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
            self.updateThreads(threads: threadsToUpdate, realm: writableRealm)
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

        try? writeTransaction { writableRealm in
            if let folder = folder.fresh(using: writableRealm) {
                createThreads(messageByUids: messageByUidsResult, folder: folder, writableRealm: writableRealm)
            }

            SentryDebug.sendMissingMessagesSentry(
                sentUids: uniqueUids,
                receivedMessages: messageByUidsResult.messages,
                folder: folder,
                newCursor: newCursor
            )
        }
    }

    // MARK: - Thread creation

    /// Main function to create threads from a list of message
    /// - Parameters:
    ///   - messageByUids: MessageByUidsResult (list of message)
    ///   - folder: Given folder
    ///   - realm: Given realm
    private func createThreads(messageByUids: MessageByUidsResult, folder: Folder, writableRealm: Realm) {
        var threadsToUpdate = Set<Thread>()
        for message in messageByUids.messages {
            guard writableRealm.object(ofType: Message.self, forPrimaryKey: message.uid) == nil else {
                SentrySDK.capture(message: "Found already existing message") { scope in
                    scope.setContext(value: ["Message": ["uid": message.uid,
                                                         "messageId": message.messageId],
                                             "Folder": ["id": message.folder?.remoteId,
                                                        "name": message.folder?.matomoName,
                                                        "cursor": message.folder?.cursor]],
                                     key: "Message context")
                }
                continue
            }
            message.inTrash = folder.role == .trash
            message.computeReference()

            let isThreadMode = UserDefaults.shared.threadMode == .conversation
            if isThreadMode {
                createConversationThread(
                    message: message,
                    folder: folder,
                    threadsToUpdate: &threadsToUpdate,
                    using: writableRealm
                )
            } else {
                createSingleMessageThread(message: message, folder: folder, threadsToUpdate: &threadsToUpdate)
            }

            if let message = writableRealm.objects(Message.self).where({ $0.uid == message.uid }).first {
                folder.messages.insert(message)
            }
        }
        updateThreads(threads: threadsToUpdate, realm: writableRealm)
    }

    /// Add the given message to existing compatible threads + Create a new thread if needed
    /// - Parameters:
    ///   - message: Given message
    ///   - folder: Given folder
    ///   - threadsToUpdate: List of thread to update after thread's creation
    ///   - realm: Given realm
    private func createConversationThread(
        message: Message,
        folder: Folder,
        threadsToUpdate: inout Set<Thread>,
        using realm: Realm
    ) {
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
            removeDuplicatedThreads(messageIds: message.linkedUids, threadsToUpdate: &threadsToUpdate, using: realm)
        }
    }

    /// Create a thread which can contain only 1 message
    /// - Parameters:
    ///   - message: Given message
    ///   - folder: Given folder
    ///   - threadsToUpdate: List of thread to update after thread's creation
    private func createSingleMessageThread(message: Message, folder: Folder, threadsToUpdate: inout Set<Thread>) {
        let thread = message.toThread().detached()
        folder.threads.insert(thread)
        threadsToUpdate.insert(thread)
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

    // MARK: - Utils

    /// Execute block
    /// Reinit folder if block failed and not already a retry
    /// - Parameters:
    ///   - folder: Given folder
    ///   - isRetrying: is function already called from a retry
    ///   - block: Block to execute
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

            try? writeTransaction { writableRealm in
                guard let folder = folder.fresh(using: writableRealm) else {
                    self.logError(.missingFolder)
                    return
                }

                writableRealm.delete(folder.messages)
                writableRealm.delete(folder.threads)
                folder.lastUpdate = nil
                folder.unreadCount = 0
                folder.resetHistoryInfo()
                folder.cursor = nil
            }
            try await messages(folder: folder, isRetrying: true)
        }
    }

    private func deleteOrphanMessagesAndThreads(writableRealm: Realm, folderId: String) {
        let orphanMessages = writableRealm.objects(Message.self).where { $0.folderId == folderId }
            .filter { $0.threads.isEmpty && $0.threadsDuplicatedIn.isEmpty }
        let orphanThreads = writableRealm.objects(Thread.self).filter { $0.folder == nil }

        writableRealm.delete(orphanMessages)
        writableRealm.delete(orphanThreads)
    }

    private func removeDuplicatedThreads(
        messageIds: MutableSet<String>,
        threadsToUpdate: inout Set<Thread>,
        using realm: Realm
    ) {
        // Create a map with all duplicated Threads of the same Thread in a list.
        let threads = realm.objects(Thread.self).where { $0.messageIds.containsAny(in: messageIds) }
        let map: [String: [Thread]] = Dictionary(grouping: threads) { $0.folderId }

        for value in map.values {
            for (index, thread) in value.enumerated() where index > 0 {
                // We want to keep only 1 duplicated Thread, so we skip the 1st one. (He's the chosen one!)
                threadsToUpdate.remove(thread)
                realm.delete(thread)
            }
        }
    }

    private func isThereDuplicatedThreads(realm: Realm, messageIds: MutableSet<String>, threadCount: Int) -> Bool {
        let foldersCount = realm.objects(Thread.self).where { $0.messageIds.containsAny(in: messageIds) }
            .distinct(by: [\Thread.folderId]).count
        return foldersCount != threadCount
    }

    private func addPreviousMessagesTo(newThread: Thread, from refMessages: Set<Message>) {
        for message in refMessages {
            newThread.messageIds.insert(objectsIn: message.linkedUids)
            newThread.addMessageIfNeeded(newMessage: message)
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

    // MARK: - Other

    func saveSearchThreads(result: ThreadResult, searchFolder: Folder) async {
        try? writeTransaction { writableRealm in
            guard let searchFolder = searchFolder.fresh(using: writableRealm) else {
                self.logError(.missingFolder)
                return
            }

            let fetchedThreads = MutableSet<Thread>()
            fetchedThreads.insert(objectsIn: result.threads ?? [])

            for thread in fetchedThreads {
                for message in thread.messages {
                    self.keepCacheAttributes(for: message, keepProperties: .standard, using: writableRealm)
                }
            }

            if result.currentOffset == 0 {
                self.clearSearchResults(searchFolder: searchFolder, writableRealm: writableRealm)

                // Update thread in Realm
                // Clean old threads after fetching first page
                searchFolder.lastUpdate = Date()
            }

            writableRealm.add(fetchedThreads, update: .modified)
            searchFolder.threads.insert(objectsIn: fetchedThreads)
        }
    }
}
