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
    private static let maxParallelUnsnooze = 4

    /// Fetch messages for given folder
    /// Then fetch messages of folder with roles if needed
    /// - Parameters:
    ///   - folder: Folder to fetch messages from
    ///   - fetchCurrentFolderCompleted: Completion once the messages have been fetched
    func threads(@EnsureFrozen folder: Folder, fetchCurrentFolderCompleted: (() -> Void) = {}) async throws {
        if folder.threadsSource == nil {
            try await refreshAllFolders()
        }
        guard let freshFolder = folder.fresh(transactionable: self)?.freeze() else { return }

        try await messages(folder: freshFolder)
        fetchCurrentFolderCompleted()

        var folderRolesToFetch = Set<FolderRole>([.inbox, .sent, .draft, .scheduledDrafts, .snoozed])
        guard let currentRole = freshFolder.role, folderRolesToFetch.contains(currentRole) else { return }

        folderRolesToFetch.remove(currentRole)
        for folderRole in folderRolesToFetch {
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
            do {
                newCursor = try await getMessagesDelta(signature: previousCursor, folder: folder)
            } catch ErrorDomain.tooManyDiffs {
                try await resetFolder(folder)

                // fetch folder as if we had no cursor
                newCursor = try await fetchOldMessagesUids(folder: folder)
            }
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

            self.deleteOrphanMessages(writableRealm: writableRealm, folderId: folder.remoteId)
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
            guard try await fetchOneOldPage(folder: folder) != nil else { break }

            messagesToFetch -= Constants.oldPageSize
        }

        if folder.role == .inbox {
            guard !Task.isCancelled else { return }
            try await unsnoozeThreadsWithNewMessage(in: folder)
        }
    }

    private func getMessagesDelta(signature: String, folder: Folder) async throws -> String {
        if folder.role == .snoozed {
            let messagesDelta: MessagesDelta<SnoozedFlags> = try await apiFetcher.messagesDelta(
                mailboxUuid: mailbox.uuid,
                folderId: folder.remoteId,
                signature: signature
            )

            try messagesDelta.ensureValidDelta()

            await handleDelta(messagesDelta: messagesDelta, folder: folder)

            return messagesDelta.cursor
        } else {
            let messagesDelta: MessagesDelta<MessageFlags> = try await apiFetcher.messagesDelta(
                mailboxUuid: mailbox.uuid,
                folderId: folder.remoteId,
                signature: signature
            )

            try messagesDelta.ensureValidDelta()

            await handleDelta(messagesDelta: messagesDelta, folder: folder)

            return messagesDelta.cursor
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
        let impactedThreadUids = try await addMessages(shortUids: nextUids, folder: folder)

        try? writeTransaction { writableRealm in
            guard let freshFolder = folder.fresh(using: writableRealm) else { return }
            let uidsToRemove = freshFolder[keyPath: direction.uidsToFetch].where { $0.uid.in(nextUids) }
            writableRealm.delete(uidsToRemove)

            if direction == .past {
                freshFolder.remainingOldMessagesToFetch -= direction.pageSize
            }

            refreshFolderThreads(threadUids: impactedThreadUids, folder: freshFolder)
        }

        return true
    }

    /// Previous page
    /// - Parameters:
    ///   - folder: Given folder
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
    ///   - messagesDelta: The list added/updated/deleted message uids
    ///   - folder: Given folder
    private func handleDelta<Flags: DeltaFlags>(messagesDelta: MessagesDelta<Flags>, folder: Folder) async {
        if let messagesDelta = messagesDelta as? MessagesDelta<MessageFlags> {
            await handleDeletedMessages(messagesDelta: messagesDelta, folder: folder)
            await handleUpdatedMessages(messagesDelta: messagesDelta, folder: folder)
        } else if let messagesDelta = messagesDelta as? MessagesDelta<SnoozedFlags> {
            await handleDeletedMessages(messagesDelta: messagesDelta, folder: folder)
            await handleUpdatedMessages(messagesDelta: messagesDelta, folder: folder)
        }

        handleNewMessageUids(messagesDelta: messagesDelta, folder: folder)
    }

    private func handleDeletedMessages(messagesDelta: MessagesDelta<MessageFlags>, folder: Folder) async {
        guard !messagesDelta.deletedShortUids.isEmpty,
              !Task.isCancelled else {
            return
        }

        // Making sure the system will not terminate the app between batches
        let expiringActivity = ExpiringActivity()
        expiringActivity.start()

        let uidsToDelete = messagesDelta.deletedShortUids

        let batchSize = 100
        for index in stride(from: 0, to: uidsToDelete.count, by: batchSize) {
            try? writeTransaction { writableRealm in
                let shortUidsBatch = Array(uidsToDelete[index ..< min(index + batchSize, uidsToDelete.count)])
                let uidsBatch = shortUidsBatch.map { computeLongMessageUid(shortUid: $0, in: folder) }

                let messagesToDelete = writableRealm.objects(Message.self).where { $0.uid.in(uidsBatch) }
                var threadsToUpdate = Set<Thread>()
                var draftsToDelete = Set<Draft>()

                for message in messagesToDelete {
                    if let draft = self.draft(messageUid: message.uid, using: writableRealm) {
                        draftsToDelete.insert(draft)
                    }
                    for parent in message.threads {
                        threadsToUpdate.insert(parent)
                    }
                }

                for draft in draftsToDelete {
                    if draft.action == nil {
                        writableRealm.delete(draft)
                    } else {
                        draft.remoteUUID = ""
                    }
                }

                writableRealm.delete(messagesToDelete)

                let threadsToDelete = threadsToUpdate.filter { $0.messageInFolderCount == 0 }
                var foldersOfDeletedThreads = Set(threadsToDelete.compactMap(\.folder))
                threadsToUpdate.subtract(threadsToDelete)

                writableRealm.delete(threadsToDelete)

                let (_, recomputedFolders) = recomputeThreadsAndUnreadCount(of: threadsToUpdate, realm: writableRealm)
                foldersOfDeletedThreads.subtract(recomputedFolders)
                recomputeUnreadCountOfFolders(foldersOfDeletedThreads)
            }
        }

        expiringActivity.endAll()
    }

    private func handleDeletedMessages(messagesDelta: MessagesDelta<SnoozedFlags>, folder: Folder) async {
        let updatedThreadUids = await updateMessages(
            with: messagesDelta.deletedShortUids,
            in: folder,
            messageUid: \.self
        ) { message, _ in
            message.snoozeState = nil
            message.snoozeUuid = nil
            message.snoozeEndDate = nil
        }

        try? writeTransaction { _ in
            refreshFolderThreads(threadUids: updatedThreadUids, folder: folder)
        }
    }

    private func handleUpdatedMessages(messagesDelta: MessagesDelta<MessageFlags>, folder: Folder) async {
        await updateMessages(with: messagesDelta.updated, in: folder, messageUid: \.shortUid) { message, flags in
            message.answered = flags.answered
            message.flagged = flags.isFavorite
            message.forwarded = flags.forwarded
            message.scheduled = flags.scheduled
            message.seen = flags.seen

            if message.snoozeState == .unsnoozed && message.seen {
                message.snoozeState = nil
                message.snoozeUuid = nil
                message.snoozeEndDate = nil
            }
        }
    }

    private func handleUpdatedMessages(messagesDelta: MessagesDelta<SnoozedFlags>, folder: Folder) async {
        await updateMessages(with: messagesDelta.updated, in: folder, messageUid: \.shortUid) { message, flags in
            message.snoozeEndDate = flags.snoozeEndDate
        }
    }

    private func handleNewMessageUids<Flags: DeltaFlags>(messagesDelta: MessagesDelta<Flags>, folder: Folder) {
        try? writeTransaction { writableRealm in
            let freshFolder = folder.fresh(using: writableRealm)
            let messageUids = messagesDelta.addedShortUids.map { MessageUid(uid: $0) }
            freshFolder?.newMessagesUidsToFetch.append(objectsIn: messageUids)

            freshFolder?.remoteUnreadCount = messagesDelta.unreadCount
        }
    }

    private func addMessages(shortUids: [String], folder: Folder) async throws -> Set<String> {
        guard !shortUids.isEmpty && !Task.isCancelled else { return [] }

        let messageByUidsResult = try await apiFetcher.messagesByUids(
            mailboxUuid: mailbox.uuid,
            folderId: folder.remoteId,
            messageUids: shortUids
        )

        for message in messageByUidsResult.messages {
            let cleanPreview = NotificationsHelper.getCleanEmojiPreviewFrom(message: message)
            message.preview = cleanPreview
        }

        var impactedThreadUids = Set<String>()
        try? writeTransaction { writableRealm in
            guard let folder = folder.fresh(using: writableRealm) else { return }
            impactedThreadUids = createThreads(messageByUids: messageByUidsResult, folder: folder, writableRealm: writableRealm)
        }
        return impactedThreadUids
    }

    @discardableResult
    private func updateMessages<T>(
        with items: [T],
        in folder: Folder,
        messageUid: KeyPath<T, String>,
        perform action: (Message, T) -> Void
    ) async -> Set<String> {
        guard !Task.isCancelled else { return [] }

        var threadsToUpdate = Set<Thread>()
        var affectedThreadUids = Set<String>()
        try? writeTransaction { writableRealm in
            for item in items {
                let messageLongUid = computeLongMessageUid(shortUid: item[keyPath: messageUid], in: folder)
                guard let message = writableRealm.object(ofType: Message.self, forPrimaryKey: messageLongUid) else { continue }

                action(message, item)
                threadsToUpdate.formUnion(message.threads)
            }

            let (affectedThreads, _) = recomputeThreadsAndUnreadCount(of: threadsToUpdate, realm: writableRealm)
            affectedThreadUids = Set(affectedThreads.map(\.uid))
        }

        return affectedThreadUids
    }

    // MARK: - Thread creation

    /// Main function to create threads from a list of message
    /// - Parameters:
    ///   - messageByUids: MessageByUidsResult (list of message)
    ///   - folder: Given folder
    ///   - writableRealm: Given realm
    private func createThreads(messageByUids: MessageByUidsResult, folder: Folder, writableRealm: Realm) -> Set<String> {
        var threadsToUpdate = Set<Thread>()
        for message in messageByUids.messages {
            SentryDebug.captureIncorrectSnoozedMessageIfNecessary(message)

            if let existingMessage = writableRealm.object(ofType: Message.self, forPrimaryKey: message.uid) {
                if folder.shouldOverrideMessage {
                    upsertMessage(message, oldMessage: existingMessage, threadsToUpdate: &threadsToUpdate, using: writableRealm)
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
        }

        let (updatedThreads, _) = recomputeThreadsAndUnreadCount(of: threadsToUpdate, realm: writableRealm)
        return Set(updatedThreads.map(\.uid))
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

    private func upsertMessage(_ message: Message, oldMessage: Message, threadsToUpdate: inout Set<Thread>, using realm: Realm) {
        keepCacheAttributes(for: message, keepProperties: .standard, using: realm)
        realm.add(message, update: .modified)

        threadsToUpdate.formUnion(oldMessage.threads)
    }

    // MARK: - Handle snoozed threads

    private func unsnoozeThreadsWithNewMessage(in folder: Folder) async throws {
        guard UserDefaults.shared.threadMode == .conversation else { return }

        let frozenThreadsToUnsnooze = fetchResults(ofType: Thread.self) { partial in
            partial.where { thread in
                let isInFolder = thread.folderId == folder.remoteId
                let isSnoozed = thread.snoozeState == .snoozed && thread.snoozeUuid != nil && thread.snoozeEndDate != nil
                let isLastMessageFromFolderNotSnoozed = !thread.isLastMessageFromFolderSnoozed

                return isInFolder && isSnoozed && isLastMessageFromFolderNotSnoozed
            }
        }.freeze()

        guard !frozenThreadsToUnsnooze.isEmpty else { return }

        let unsnoozedMessages: [String] = await Array(frozenThreadsToUnsnooze).concurrentCompactMap(
            customConcurrency: Self.maxParallelUnsnooze
        ) { thread in
            guard let lastMessageSnoozed = thread.messages.last(where: { $0.isSnoozed }),
                  thread.lastMessageFromFolder?.isSnoozed == false else {
                return nil
            }

            do {
                try await self.apiFetcher.deleteSnooze(message: lastMessageSnoozed, mailbox: self.mailbox)
                return lastMessageSnoozed.uid
            } catch let error as MailApiError where error == .apiMessageNotSnoozed || error == .apiObjectNotFound {
                self.manuallyUnsnoozeThreadInRealm(thread: thread)
                return nil
            } catch {
                SentryDebug.captureManuallyUnsnoozeError(error: error)
                return nil
            }
        }

        guard !Task.isCancelled, !unsnoozedMessages.isEmpty else { return }
        Task {
            guard let snoozedFolder = getFolder(with: .snoozed)?.freezeIfNeeded() else { return }
            await refreshFolderContent(snoozedFolder)
        }
    }

    private func manuallyUnsnoozeThreadInRealm(thread: Thread) {
        try? writeTransaction { writableRealm in
            guard let freshThread = thread.fresh(using: writableRealm) else { return }

            for message in freshThread.messages {
                message.snoozeState = nil
                message.snoozeUuid = nil
                message.snoozeEndDate = nil
            }

            try? freshThread.recomputeOrFail(currentAccountEmail: mailbox.email)
            let duplicatesThreads = Set(freshThread.duplicates.flatMap { $0.threads })
            for duplicateThread in duplicatesThreads {
                try? duplicateThread.recomputeOrFail(currentAccountEmail: mailbox.email)
            }
        }
    }

    // MARK: - Utils

    private func deleteOrphanMessages(writableRealm: Realm, folderId: String) {
        let orphanMessages = writableRealm.objects(Message.self).where { $0.folderId == folderId }
            .filter { $0.threads.isEmpty && $0.threadsDuplicatedIn.isEmpty }

        writableRealm.delete(orphanMessages)
    }

    private func resetFolder(_ folder: Folder) async throws {
        try writeTransaction { realm in
            guard let liveFolder = folder.fresh(using: realm) else { return }

            liveFolder.remainingOldMessagesToFetch = Constants.messageQuantityLimit
            liveFolder.oldMessagesUidsToFetch.removeAll()
            liveFolder.newMessagesUidsToFetch.removeAll()
            realm.delete(liveFolder.threads)
            realm.delete(liveFolder.messages)
            liveFolder.lastUpdate = nil
            liveFolder.cursor = nil
            liveFolder.unreadCount = 0
        }
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

    @discardableResult
    private func recomputeThreadsAndUnreadCount(of threads: Set<Thread>, realm: Realm) -> (Set<Thread>, Set<Folder>) {
        var threadsToRecompute = threads
        let duplicatesThreads = Set(threads.flatMap { $0.duplicates.flatMap { $0.threads } })
        threadsToRecompute.formUnion(duplicatesThreads)

        let recomputedThreads = threadsToRecompute.filter { thread in
            do {
                try thread.recomputeOrFail(currentAccountEmail: mailbox.email)
                return true
            } catch {
                realm.delete(thread)
                return false
            }
        }

        return (recomputedThreads, recomputeUnreadCountOfFolders(containing: recomputedThreads))
    }

    /// Refresh the unread count of the folders of the given threads
    /// When we refresh a thread from INBOX or SNOOZED, we should refresh both folders
    @discardableResult
    private func recomputeUnreadCountOfFolders(containing threads: Set<Thread>) -> Set<Folder> {
        let foldersToRefresh = Set(threads.compactMap(\.folder))
        return recomputeUnreadCountOfFolders(foldersToRefresh)
    }

    /// Refresh the unread count of the folders of the given threads
    /// When we refresh a thread from INBOX or SNOOZED, we should refresh both folders
    @discardableResult
    private func recomputeUnreadCountOfFolders(_ folders: Set<Folder>) -> Set<Folder> {
        var foldersToRefresh = folders
        let folderRolesToRefresh = Set(folders.compactMap(\.role))

        let folderRolesToRefreshTogether = Set([FolderRole.inbox, FolderRole.snoozed])
        if !folderRolesToRefresh.union(folderRolesToRefreshTogether).isEmpty {
            for folderRole in folderRolesToRefreshTogether {
                guard let folder = getFolder(with: folderRole) else { continue }
                foldersToRefresh.insert(folder)
            }
        }

        for folder in foldersToRefresh {
            folder.computeUnreadCount()
        }

        return foldersToRefresh
    }

    private func insertMessageToRealm(message: Message, using realm: Realm) -> Thread {
        let thread = message.toThread().detached()
        realm.add(thread)

        return thread
    }

    private func refreshFolderThreads(threadUids: Set<String>, folder: Folder) {
        let threadsFromRealm = fetchResults(ofType: Thread.self) { partial in
            return partial.where { $0.uid.in(threadUids) }
        }
        let threads = Set(threadsFromRealm)

        upsertThreadsAndMessages(threads: threads, in: folder)
        for associatedFolder in folder.associatedFolders {
            upsertThreadsAndMessages(threads: threads, in: associatedFolder)
        }
    }

    private func upsertThreadsAndMessages(threads: Set<Thread>, in folder: Folder) {
        guard let freshFolder = folder.fresh(transactionable: self) else { return }

        let threadsToAdd = threads.filter { freshFolder.threadBelongsToFolder($0) }
        let threadsToDelete = threads.subtracting(threadsToAdd)
        freshFolder.threads.upsert(append: threadsToAdd, remove: threadsToDelete)

        let messagesToAdd = Set(threadsToAdd.flatMap { thread in
            thread.messages.filter { $0.originalThread?.uid == thread.uid }
        })
        let messagesToDelete = Set(threadsToDelete.flatMap { thread in
            thread.messages.filter { $0.originalThread?.uid == thread.uid }
        })
        freshFolder.messages.upsert(append: messagesToAdd, remove: messagesToDelete)
    }

    private func computeLongMessageUid(shortUid: String, in folder: Folder) -> String {
        guard let sourceFolder = folder.threadsSource else { return "" }
        return "\(shortUid)@\(sourceFolder.remoteId)"
    }

    // MARK: - Other

    func saveSearchThreads(result: ThreadResult, searchFolder: Folder) async {
        try? writeTransaction { writableRealm in
            guard let liveSearchFolder = searchFolder.fresh(using: writableRealm) else {
                self.logError(.missingFolder)
                return
            }

            let resultThreads = result.threads?.map { Thread(value: $0) } ?? []
            let fetchedThreads = MutableSet<Thread>()
            fetchedThreads.insert(objectsIn: resultThreads)

            let allUniqueFetchedMessagesUids = Set(fetchedThreads.flatMap { $0.messages.map(\.uid) })
            for messageUid in allUniqueFetchedMessagesUids {
                guard let liveMessage = writableRealm.object(ofType: Message.self, forPrimaryKey: messageUid) else {
                    continue
                }
                self.keepCacheAttributes(for: liveMessage, keepProperties: .standard, using: writableRealm)
                writableRealm.add(liveMessage, update: .modified)
            }

            if result.currentOffset == 0 {
                self.clearSearchResults(searchFolder: liveSearchFolder, writableRealm: writableRealm)

                // Update thread in Realm
                // Clean old threads after fetching first page
                liveSearchFolder.lastUpdate = Date()
            }

            writableRealm.add(fetchedThreads, update: .modified)
            liveSearchFolder.threads.insert(objectsIn: fetchedThreads)
        }
    }
}
