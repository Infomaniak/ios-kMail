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

import Foundation
import InfomaniakCore
import InfomaniakCoreDB
import RealmSwift
import Sentry

enum PageDirection {
    case future
    case past

    var pageSize: Int {
        switch self {
        case .future:
            return Constants.newPageSize
        case .past:
            return Constants.oldPageSize
        }
    }

    var uidsToFetch: KeyPath<Folder, List<MessageUid>> {
        switch self {
        case .future:
            return \.newMessagesUidsToFetch
        case .past:
            return \.oldMessagesUidsToFetch
        }
    }
}

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
                return [.sent, .draft, .scheduledDrafts]
            case .sent:
                return [.inbox, .draft, .scheduledDrafts]
            case .draft:
                return [.inbox, .sent, .scheduledDrafts]
            case .scheduledDrafts:
                return [.inbox, .sent, .draft]
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
    func messages(folder: Folder) async throws {
        guard !Task.isCancelled else { return }

        let liveFolder = folder.fresh(transactionable: self)
        let previousCursor = liveFolder?.cursor
        let newCursor: String

        if let previousCursor {
            let messagesDelta = try await apiFetcher.messagesDelta(
                mailboxUUid: mailbox.uuid,
                folderId: folder.remoteId,
                signature: previousCursor
            )

            newCursor = messagesDelta.cursor
            try await handleDelta(messagesDelta: messagesDelta, folder: folder)
        } else {
            newCursor = try await fetchOldMessagesUids(folder: folder)
        }

        guard !Task.isCancelled else { return }

        try? writeTransaction { writableRealm in
            guard let folder = folder.fresh(using: writableRealm) else {
                self.logError(.missingFolder)
                return
            }

            folder.computeUnreadCount()
            folder.cursor = newCursor
            folder.lastUpdate = Date()

            SentryDebug.searchForOrphanMessages(
                folderId: folder.remoteId,
                using: writableRealm,
                previousCursor: previousCursor,
                newCursor: newCursor
            )
            SentryDebug.searchForOrphanThreads(
                using: writableRealm,
                previousCursor: previousCursor,
                newCursor: newCursor
            )

            self.deleteOrphanMessagesAndThreads(writableRealm: writableRealm, folderId: folder.remoteId)
        }

        /// We will now fetch new messages
        while try await fetchOnePage(folder: folder, direction: .future) {
            guard !Task.isCancelled else { return }
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
        var messagesToFetch = folderPrevious.remainingOldMessagesToFetch
        while messagesToFetch > 0 {
            guard !Task.isCancelled else { return }
            guard try await fetchOneOldPage(folder: folder) != nil else { return }

            messagesToFetch -= Constants.oldPageSize
        }
    }

    /// This function get all the messages uids from the chosen folder
    private func fetchOldMessagesUids(folder: Folder) async throws -> String {
        /// Get ALL uids
        let messageUidsResult = try await apiFetcher.messagesUids(mailboxUuid: mailbox.uuid, folderId: folder.remoteId)

        try? writeTransaction { writableRealm in
            guard let folder = folder.fresh(using: writableRealm) else {
                self.logError(.missingFolder)
                return
            }

            folder.oldMessagesUidsToFetch = messageUidsResult.messageShortUids.map { MessageUid(uid: $0) }.toRealmList()
        }

        return messageUidsResult.cursor
    }

    private func fetchOnePage(folder: Folder, direction: PageDirection) async throws -> Bool {
        guard let liveFolder = folder.fresh(transactionable: self) else { return false }

        let uidsToFetch = liveFolder[keyPath: direction.uidsToFetch]
        guard !uidsToFetch.isEmpty else { return false }

        let range = 0 ..< min(uidsToFetch.count, direction.pageSize)
        let nextUids: [String] = uidsToFetch[range].map { $0.uid }
        try await addMessages(shortUids: nextUids, folder: folder)

        try? writeTransaction { writableRealm in
            guard let freshFolder = folder.fresh(using: writableRealm) else { return }
            let uidsToRemove = freshFolder[keyPath: direction.uidsToFetch].where { $0.uid.in(nextUids) }
            writableRealm.delete(uidsToRemove)

            if direction == .past {
                freshFolder.remainingOldMessagesToFetch -= direction.pageSize
            }

            refreshFolderThreads(folder: freshFolder, using: writableRealm)
        }

        return true
    }

    /// Previous page
    /// - Parameters:
    ///   - folder: Given folder
    ///   - direction: Following or previous page to fetch
    /// - Returns: Returns number of threads created (`nil` if nothing to fetch)
    func fetchOneOldPage(folder: Folder) async throws -> Int? {
        guard let liveFolder = folder.fresh(transactionable: self) else { return nil }
        let initialThreadsCount = liveFolder.threads.count

        guard try await fetchOnePage(folder: folder, direction: .past),
              let freshFolder = folder.fresh(transactionable: self) else { return nil }

        let newThreadsCount = freshFolder.threads.count
        return newThreadsCount - initialThreadsCount
    }

    // MARK: - Handle MessagesUids

    /// Handle MessagesUids from Delta
    /// Will delete, update and add messages from uids
    /// - Parameters:
    ///   - messageDelta: The list added/updated/deleted message uids
    ///   - folder: Given folder
    private func handleDelta(messagesDelta: MessagesDelta, folder: Folder) async throws {
        await deleteMessages(uids: messagesDelta.deletedShortUids, folder: folder)

        await updateMessages(updates: messagesDelta.updated, folder: folder)

        // Add Uids to fetch in the folder
        try? writeTransaction { writableRealm in
            let freshFolder = folder.fresh(using: writableRealm)
            let messageUids = messagesDelta.addedShortUids.map { MessageUid(uid: $0) }
            freshFolder?.newMessagesUidsToFetch.append(objectsIn: messageUids)

            freshFolder?.remoteUnreadCount = messagesDelta.unreadCount
        }
    }

    private func deleteMessages(uids: [String], folder: Folder) async {
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
                let shortUidsBatch = Array(uids[index ..< min(index + batchSize, uids.count)])
                let uidsBatch = shortUidsBatch.map { Constants.longUid(from: $0, folderId: folder.remoteId) }

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

    private func addMessages(shortUids: [String], folder: Folder) async throws {
        guard !shortUids.isEmpty && !Task.isCancelled else { return }

        let messageByUidsResult = try await apiFetcher.messagesByUids(
            mailboxUuid: mailbox.uuid,
            folderId: folder.remoteId,
            messageUids: shortUids
        )

        try? writeTransaction { writableRealm in
            if let folder = folder.fresh(using: writableRealm) {
                createThreads(messageByUids: messageByUidsResult, folder: folder, writableRealm: writableRealm)
            }
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
                                             "Folder": ["id": message.folderId,
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
                createSingleMessageThread(message: message, threadsToUpdate: &threadsToUpdate, using: writableRealm)
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
            existingThreads: existingThreads,
            using: realm
        ) {
            threadsToUpdate.insert(newThread)
        }

        var allExistingMessages = Set(existingThreads.flatMap(\.messages))
        allExistingMessages.insert(message)

        for thread in existingThreads {
            for existingMessage in allExistingMessages {
                if !thread.messages.map(\.uid).contains(existingMessage.uid) {
                    thread.addMessageIfNeeded(newMessage: existingMessage.fresh(using: realm) ?? existingMessage, using: realm)
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
    private func createSingleMessageThread(message: Message, threadsToUpdate: inout Set<Thread>, using realm: Realm) {
        let thread = insertMessageToRealm(message: message, using: realm)
        threadsToUpdate.insert(thread)
    }

    private func createNewThreadIfRequired(for message: Message, folder: Folder, existingThreads: [Thread],
                                           using realm: Realm) -> Thread? {
        guard !folder.shouldContainsSingleMessageThreads else {
            let thread = insertMessageToRealm(message: message, using: realm)
            return thread
        }

        guard !existingThreads.contains(where: { $0.folderId == folder.remoteId }) else {
            return nil
        }

        let thread = insertMessageToRealm(message: message, using: realm)

        let refMessages = existingThreads.flatMap(\.messages).toSet()
        addPreviousMessagesTo(newThread: thread, from: refMessages, using: realm)

        return thread
    }

    // MARK: - Utils

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

    private func addPreviousMessagesTo(newThread: Thread, from refMessages: Set<Message>, using realm: Realm) {
        for message in refMessages {
            newThread.addMessageIfNeeded(newMessage: message, using: realm)
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

    private func insertMessageToRealm(message: Message, using realm: Realm) -> Thread {
        let thread = message.toThread().detached()
        realm.add(thread)

        return thread
    }

    private func refreshFolderThreads(folder: Folder, using realm: Realm) {
        let threads = realm.objects(Thread.self).where { thread in
            folder.threadBelongsToFolder(thread)
        }

        folder.threads.removeAll()
        folder.threads.insert(objectsIn: threads)
    }

    // MARK: - Other

    func saveSearchThreads(result: ThreadResult, searchFolder: Folder) async {
        try? writeTransaction { writableRealm in
            guard let searchFolder = searchFolder.fresh(using: writableRealm) else {
                self.logError(.missingFolder)
                return
            }

            let resultThreads = result.threads?.map { Thread(value: $0) } ?? []
            let fetchedThreads = MutableSet<Thread>()
            fetchedThreads.insert(objectsIn: resultThreads)

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
