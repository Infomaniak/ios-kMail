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
import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailResources
import RealmSwift
import Sentry
import SwiftRegex

public final class MailboxManager: ObservableObject {
    @LazyInjectService private var snackbarPresenter: SnackBarPresentable

    public final class MailboxManagerConstants {
        private let fileManager = FileManager.default
        public let rootDocumentsURL: URL
        public let groupDirectoryURL: URL
        public let cacheDirectoryURL: URL

        init() {
            @InjectService var appGroupPathProvider: AppGroupPathProvidable
            groupDirectoryURL = appGroupPathProvider.groupDirectoryURL
            rootDocumentsURL = appGroupPathProvider.realmRootURL
            cacheDirectoryURL = appGroupPathProvider.cacheDirectoryURL

            DDLogInfo("groupDirectoryURL: \(groupDirectoryURL)")
            DDLogInfo(
                "App working path is: \(fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.absoluteString ?? "")"
            )
            DDLogInfo("Group container path is: \(groupDirectoryURL.absoluteString)")
        }
    }

    public static let constants = MailboxManagerConstants()

    public let realmConfiguration: Realm.Configuration
    public let mailbox: Mailbox
    public let account: Account

    public let apiFetcher: MailApiFetcher
    public let contactManager: ContactManager
    private let backgroundRealm: BackgroundRealm

    private lazy var refreshActor = RefreshActor(mailboxManager: self)

    public init(account: Account, mailbox: Mailbox, apiFetcher: MailApiFetcher, contactManager: ContactManager) {
        self.account = account
        self.mailbox = mailbox
        self.apiFetcher = apiFetcher
        self.contactManager = contactManager
        let realmName = "\(mailbox.userId)-\(mailbox.mailboxId).realm"
        realmConfiguration = Realm.Configuration(
            fileURL: MailboxManager.constants.rootDocumentsURL.appendingPathComponent(realmName),
            schemaVersion: 17,
            migrationBlock: { migration, oldSchemaVersion in
                // No migration needed from 0 to 16
                if oldSchemaVersion < 17 {
                    // Remove signatures without `senderName` and `senderEmailIdn`
                    migration.deleteData(forType: Signature.className())
                }
            },
            objectTypes: [
                Folder.self,
                Thread.self,
                Message.self,
                Body.self,
                Attachment.self,
                Recipient.self,
                Draft.self,
                Signature.self,
                SearchHistory.self
            ]
        )
        backgroundRealm = BackgroundRealm(configuration: realmConfiguration)
    }

    public func getRealm() -> Realm {
        do {
            let realm = try Realm(configuration: realmConfiguration)
            realm.refresh()
            return realm
        } catch {
            // We can't recover from this error but at least we report it correctly on Sentry
            Logging.reportRealmOpeningError(error, realmConfiguration: realmConfiguration)
        }
    }

    /// Delete all mailbox data cache for user
    /// - Parameters:
    ///   - userId: User ID
    ///   - mailboxId: Mailbox ID (`nil` if all user mailboxes)
    public static func deleteUserMailbox(userId: Int, mailboxId: Int? = nil) {
        let files = (try? FileManager.default
            .contentsOfDirectory(at: MailboxManager.constants.rootDocumentsURL, includingPropertiesForKeys: nil))
        files?.forEach { file in
            if let matches = Regex(pattern: "(\\d+)-(\\d+).realm.*")?.firstMatch(in: file.lastPathComponent), matches.count > 2 {
                let fileUserId = matches[1]
                let fileMailboxId = matches[2]
                if Int(fileUserId) == userId && (mailboxId == nil || Int(fileMailboxId) == mailboxId) {
                    DDLogInfo("Deleting file: \(file.lastPathComponent)")
                    try? FileManager.default.removeItem(at: file)
                }
            }
        }
    }

    // MARK: - Signatures

    public func refreshAllSignatures() async throws {
        // Get from API
        let signaturesResult = try await apiFetcher.signatures(mailbox: mailbox)
        let updatedSignatures = Array(signaturesResult.signatures)

        await backgroundRealm.execute { realm in
            let signaturesToDelete: [Signature] // no longer present server side
            let signaturesToUpdate: [Signature] // updated signatures
            let signaturesToAdd: [Signature] // new signatures

            // fetch all local signatures
            let existingSignatures = Array(realm.objects(Signature.self))

            signaturesToAdd = updatedSignatures.filter { updatedElement in
                !existingSignatures.contains(updatedElement)
            }

            signaturesToUpdate = updatedSignatures.filter { updatedElement in
                existingSignatures.contains(updatedElement)
            }

            signaturesToDelete = existingSignatures.filter { existingElement in
                !updatedSignatures.contains(existingElement)
            }

            // NOTE: local drafts in `signaturesToDelete` should be migrated to use the new default signature.

            // Update signatures in Realm
            try? realm.safeWrite {
                realm.add(signaturesToUpdate, update: .modified)
                realm.delete(signaturesToDelete)
                realm.add(signaturesToAdd, update: .modified)
            }
        }
    }

    public func updateSignature(signature: Signature) async throws {
        _ = try await apiFetcher.updateSignature(mailbox: mailbox, signature: signature)
        try await refreshAllSignatures()
    }

    public func getStoredSignatures(using realm: Realm? = nil) -> [Signature] {
        let realm = realm ?? getRealm()
        return Array(realm.objects(Signature.self))
    }

    // MARK: - Folders

    public func folders() async throws {
        // Get from Realm
        guard ReachabilityListener.instance.currentStatus != .offline else {
            return
        }
        // Get from API
        let folderResult = try await apiFetcher.folders(mailbox: mailbox)
        let newFolders = getSubFolders(from: folderResult)

        await backgroundRealm.execute { realm in
            for folder in newFolders {
                self.keepCacheAttributes(for: folder, using: realm)
            }

            let cachedFolders = realm.objects(Folder.self)

            // Update folders in Realm
            try? realm.safeWrite {
                // Remove old folders
                realm.add(folderResult, update: .modified)
                let toDeleteFolders = Set(cachedFolders).subtracting(Set(newFolders)).filter { $0.id != Constants.searchFolderId }
                var toDeleteThreads = [Thread]()

                // Threads contains in folders to delete
                let mayBeDeletedThreads = Set(toDeleteFolders.flatMap(\.threads))
                // Messages contains in folders to delete
                let toDeleteMessages = Set(toDeleteFolders.flatMap(\.messages))

                // Delete thread if all his messages are deleted
                for thread in mayBeDeletedThreads where Set(thread.messages).isSubset(of: toDeleteMessages) {
                    toDeleteThreads.append(thread)
                }

                realm.delete(toDeleteMessages)
                realm.delete(toDeleteThreads)
                realm.delete(toDeleteFolders)
            }
        }
    }

    /// Get the folder with the corresponding role in Realm.
    /// - Parameters:
    ///   - role: Role of the folder.
    ///   - realm: The Realm instance to use. If this parameter is `nil`, a new one will be created.
    /// - Returns: The folder with the corresponding role, or `nil` if no such folder has been found.
    public func getFolder(with role: FolderRole, using realm: Realm? = nil) -> Folder? {
        let realm = realm ?? getRealm()
        return realm.objects(Folder.self).where { $0.role == role }.first
    }

    /// Get all the real folders in Realm
    /// - Parameters:
    ///   - realm: The Realm instance to use. If this parameter is `nil`, a new one will be created.
    /// - Returns: The list of real folders.
    public func getFolders(using realm: Realm? = nil) -> [Folder] {
        let realm = realm ?? getRealm()
        return Array(realm.objects(Folder.self).where { $0.toolType == nil })
    }

    public func createFolder(name: String, parent: Folder? = nil) async throws -> Folder {
        var folder = try await apiFetcher.create(mailbox: mailbox, folder: NewFolder(name: name, path: parent?.path))
        await backgroundRealm.execute { realm in
            try? realm.safeWrite {
                realm.add(folder)
                if let parent {
                    parent.fresh(using: realm)?.children.insert(folder)
                }
            }
            folder = folder.freeze()
        }
        return folder
    }

    // MARK: RefreshActor

    public func flushFolder(folder: Folder) async throws -> Bool {
        return try await refreshActor.flushFolder(folder: folder, mailbox: mailbox, apiFetcher: apiFetcher)
    }

    public func refreshFolder(from messages: [Message], additionalFolder: Folder? = nil) async throws {
        try await refreshActor.refreshFolder(from: messages, additionalFolder: additionalFolder)
    }

    public func refresh(folder: Folder) async {
        await refreshActor.refresh(folder: folder)
    }

    public func cancelRefresh() async {
        await refreshActor.cancelRefresh()
    }

    // MARK: - Thread

    public func threads(folder: Folder, fetchCurrentFolderCompleted: (() -> Void) = {}) async throws {
        try await messages(folder: folder.freezeIfNeeded())
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

    private func deleteMessages(uids: [String]) async {
        guard !uids.isEmpty && !Task.isCancelled else { return }

        await backgroundRealm.execute { realm in
            let batchSize = 100
            for index in stride(from: 0, to: uids.count, by: batchSize) {
                autoreleasepool {
                    let uidsBatch = Array(uids[index ..< min(index + batchSize, uids.count)])

                    let messagesToDelete = realm.objects(Message.self).where { $0.uid.in(uidsBatch) }
                    var threadsToUpdate = Set<Thread>()
                    var threadsToDelete = Set<Thread>()
                    var draftsToDelete = Set<Draft>()

                    for message in messagesToDelete {
                        if let draft = self.draft(messageUid: message.uid, using: realm) {
                            draftsToDelete.insert(draft)
                        }
                        for parent in message.threads {
                            threadsToUpdate.insert(parent)
                        }
                    }

                    let foldersToUpdate = Set(threadsToUpdate.compactMap(\.folder))

                    try? realm.safeWrite {
                        realm.delete(draftsToDelete)
                        realm.delete(messagesToDelete)
                        for thread in threadsToUpdate {
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
                        realm.delete(threadsToDelete)
                        for updateFolder in foldersToUpdate {
                            updateFolder.computeUnreadCount()
                        }
                    }
                }
            }
        }
    }

    private func saveThreads(result: ThreadResult, parent: Folder) async {
        await backgroundRealm.execute { realm in
            guard let parentFolder = parent.fresh(using: realm) else { return }

            let fetchedThreads = MutableSet<Thread>()
            fetchedThreads.insert(objectsIn: result.threads ?? [])

            for thread in fetchedThreads {
                for message in thread.messages {
                    self.keepCacheAttributes(for: message, keepProperties: .standard, using: realm)
                }
            }

            // Update thread in Realm
            try? realm.safeWrite {
                // Clean old threads after fetching first page
                if result.currentOffset == 0 {
                    parentFolder.lastUpdate = Date()
                    realm.delete(parentFolder.threads.flatMap(\.messages).filter { $0.fromSearch == true })
                    realm.delete(parentFolder.threads.filter { $0.fromSearch == true })
                }
                realm.add(fetchedThreads, update: .modified)
                parentFolder.threads.insert(objectsIn: fetchedThreads)
                parentFolder.unreadCount = result.folderUnseenMessages
            }
        }
    }

    public func toggleRead(threads: [Thread]) async throws {
        if threads.contains(where: \.hasUnseenMessages) {
            var messages = threads.flatMap(\.messages)
            messages.append(contentsOf: messages.flatMap(\.duplicates))
            try await markAsSeen(messages: messages, seen: true)
        } else {
            let messages = threads.flatMap { thread in
                thread.lastMessageAndItsDuplicateToExecuteAction(currentMailboxEmail: mailbox.email)
            }
            try await markAsSeen(messages: messages, seen: false)
        }
    }

    public func move(threads: [Thread], to folderRole: FolderRole) async throws -> UndoRedoAction {
        guard let folder = getFolder(with: folderRole)?.freeze() else { throw MailError.folderNotFound }
        return try await move(threads: threads, to: folder)
    }

    public func move(threads: [Thread], to folder: Folder) async throws -> UndoRedoAction {
        var messages = threads.flatMap(\.messages).filter { $0.folder == threads.first?.folder }
        messages.append(contentsOf: messages.flatMap(\.duplicates))

        return try await move(messages: messages, to: folder)
    }

    public func moveOrDelete(threads: [Thread]) async throws {
        let messagesToMoveOrDelete = threads.flatMap(\.messages)
        try await moveOrDelete(messages: messagesToMoveOrDelete)
    }

    public func toggleStar(threads: [Thread]) async throws {
        let messagesToToggleStar = threads.flatMap { thread in
            thread.lastMessageAndItsDuplicateToExecuteAction(currentMailboxEmail: mailbox.email)
        }
        try await toggleStar(messages: messagesToToggleStar)
    }

    // MARK: - Search

    public func initSearchFolder() -> Folder {
        let searchFolder = Folder(
            id: Constants.searchFolderId,
            path: "",
            name: "",
            isFavorite: false,
            separator: "/",
            children: [],
            toolType: .search
        )

        let realm = getRealm()
        try? realm.uncheckedSafeWrite {
            realm.add(searchFolder, update: .modified)
        }
        return searchFolder
    }

    public func searchThreads(searchFolder: Folder?, filterFolderId: String, filter: Filter = .all,
                              searchFilter: [URLQueryItem] = []) async throws -> ThreadResult {
        let threadResult = try await apiFetcher.threads(
            mailbox: mailbox,
            folderId: filterFolderId,
            filter: filter,
            searchFilter: searchFilter,
            isDraftFolder: false
        )

        await backgroundRealm.execute { realm in
            for thread in threadResult.threads ?? [] {
                thread.fromSearch = true

                for message in thread.messages where realm.object(ofType: Message.self, forPrimaryKey: message.uid) == nil {
                    message.fromSearch = true
                }
            }
        }

        if let searchFolder {
            await saveThreads(result: threadResult, parent: searchFolder)
        }

        return threadResult
    }

    public func searchThreads(searchFolder: Folder?, from resource: String,
                              searchFilter: [URLQueryItem] = []) async throws -> ThreadResult {
        let threadResult = try await apiFetcher.threads(from: resource, searchFilter: searchFilter)

        let realm = getRealm()
        for thread in threadResult.threads ?? [] {
            thread.fromSearch = true

            for message in thread.messages where realm.object(ofType: Message.self, forPrimaryKey: message.uid) == nil {
                message.fromSearch = true
            }
        }

        if let searchFolder {
            await saveThreads(result: threadResult, parent: searchFolder)
        }

        return threadResult
    }

    public func searchThreadsOffline(searchFolder: Folder?, filterFolderId: String,
                                     searchFilters: [SearchCondition]) async {
        await backgroundRealm.execute { realm in
            guard let searchFolder = searchFolder?.fresh(using: realm) else { return }

            try? realm.safeWrite {
                realm.delete(realm.objects(Message.self).where { $0.fromSearch == true })
                realm.delete(searchFolder.threads.where { $0.fromSearch == true })
                searchFolder.threads.removeAll()
            }

            var predicates: [NSPredicate] = []
            for searchFilter in searchFilters {
                switch searchFilter {
                case .filter(let filter):
                    switch filter {
                    case .seen:
                        predicates.append(NSPredicate(format: "seen = true"))
                    case .unseen:
                        predicates.append(NSPredicate(format: "seen = false"))
                    case .starred:
                        predicates.append(NSPredicate(format: "flagged = true"))
                    case .unstarred:
                        predicates.append(NSPredicate(format: "flagged = false"))
                    default:
                        break
                    }
                case .from(let from):
                    predicates.append(NSPredicate(format: "ANY from.email = %@", from))
                case .contains(let content):
                    predicates
                        .append(
                            NSPredicate(format: "subject CONTAINS[c] %@ OR preview CONTAINS[c] %@",
                                        content, content, content)
                        )
                case .everywhere(let searchEverywhere):
                    if !searchEverywhere {
                        predicates.append(NSPredicate(format: "folderId = %@", filterFolderId))
                    }
                case .attachments(let searchAttachments):
                    if searchAttachments {
                        predicates.append(NSPredicate(format: "hasAttachments = true"))
                    }
                }
            }

            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

            let filteredMessages = realm.objects(Message.self).filter(compoundPredicate)

            // Update thread in Realm
            try? realm.safeWrite {
                for message in filteredMessages {
                    let newMessage = message.detached()
                    newMessage.uid = "offline\(newMessage.uid)"
                    newMessage.fromSearch = true

                    let newThread = Thread(
                        uid: "offlineThread\(message.uid)",
                        messages: [newMessage],
                        unseenMessages: 0,
                        from: Array(message.from.detached()),
                        to: Array(message.to.detached()),
                        date: newMessage.date,
                        hasAttachments: newMessage.hasAttachments,
                        hasDrafts: newMessage.isDraft,
                        flagged: newMessage.flagged,
                        answered: newMessage.answered,
                        forwarded: newMessage.forwarded
                    )
                    newThread.fromSearch = true
                    newThread.subject = message.subject
                    searchFolder.threads.insert(newThread)
                }
            }
        }
    }

    public func searchHistory(using realm: Realm? = nil) -> SearchHistory {
        let realm = realm ?? getRealm()
        if let searchHistory = realm.objects(SearchHistory.self).first {
            return searchHistory.freeze()
        }
        let newSearchHistory = SearchHistory()
        try? realm.uncheckedSafeWrite {
            realm.add(newSearchHistory)
        }
        return newSearchHistory
    }

    public func update(searchHistory: SearchHistory, with value: String) async -> SearchHistory {
        return await backgroundRealm.execute { realm in
            guard let liveSearchHistory = realm.objects(SearchHistory.self).first else { return searchHistory }
            try? realm.safeWrite {
                if let indexToRemove = liveSearchHistory.history.firstIndex(of: value) {
                    liveSearchHistory.history.remove(at: indexToRemove)
                }
                liveSearchHistory.history.insert(value, at: 0)
            }
            return liveSearchHistory.freeze()
        }
    }

    public func delete(searchHistory: SearchHistory, with value: String) async -> SearchHistory {
        return await backgroundRealm.execute { realm in
            guard let liveSearchHistory = realm.objects(SearchHistory.self).first else { return searchHistory }
            try? realm.safeWrite {
                if let indexToRemove = liveSearchHistory.history.firstIndex(of: value) {
                    liveSearchHistory.history.remove(at: indexToRemove)
                }
            }
            return liveSearchHistory.freeze()
        }
    }

    // MARK: - Message

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

    public func messages(folder: Folder) async throws {
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

    public func fetchOnePage(folder: Folder, direction: NewMessagesDirection? = nil) async throws -> Bool {
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
                createMultiMessagesThreads(messageByUids: messageByUidsResult, folder: folder, using: realm)
            }
            SentryDebug.sendMissingMessagesSentry(
                sentUids: uniqueUids,
                receivedMessages: messageByUidsResult.messages,
                folder: folder,
                newCursor: newCursor
            )
        }
    }

    private func createMultiMessagesThreads(messageByUids: MessageByUidsResult, folder: Folder, using realm: Realm) {
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
                let existingThreads = Array(realm.objects(Thread.self)
                    .where { $0.messageIds.containsAny(in: message.linkedUids) })

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

                if let message = realm.objects(Message.self).first(where: { $0.uid == message.uid }) {
                    folder.messages.insert(message)
                }
            }
            self.updateThreads(threads: threadsToUpdate, realm: realm)
        }
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

    public func message(message: Message) async throws {
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

    public func attachmentData(attachment: Attachment) async throws -> Data {
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

    public func saveAttachmentLocally(attachment: Attachment) async {
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

    public func moveOrDelete(messages: [Message]) async throws {
        let messagesGroupedByFolderId = Dictionary(grouping: messages, by: \.folderId)

        await withThrowingTaskGroup(of: Void.self) { group in
            for messagesInSameFolder in messagesGroupedByFolderId.values {
                group.addTask {
                    try await self.moveOrDeleteMessagesInSameFolder(messages: messagesInSameFolder)
                }
            }
        }
    }

    public func markAsSeen(message: Message, seen: Bool = true) async throws {
        if seen {
            var messages = [message]
            messages.append(contentsOf: message.duplicates)
            try await markAsSeen(messages: messages, seen: seen)
        } else {
            try await markAsSeen(messages: [message], seen: seen)
        }
    }

    private func markAsSeen(messages: [Message], seen: Bool) async throws {
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

    public func move(messages: [Message], to folderRole: FolderRole) async throws -> UndoRedoAction {
        guard let folder = getFolder(with: folderRole)?.freeze() else { throw MailError.folderNotFound }
        return try await move(messages: messages, to: folder)
    }

    public func move(messages: [Message], to folder: Folder) async throws -> UndoRedoAction {
        let response = try await apiFetcher.move(mailbox: mailbox, messages: messages, destinationId: folder._id)
        try await refreshFolder(from: messages, additionalFolder: folder)
        return undoRedoAction(for: response, and: messages)
    }

    public func delete(messages: [Message]) async throws {
        _ = try await apiFetcher.delete(mailbox: mailbox, messages: messages)
        try await refreshFolder(from: messages)
    }

    public func toggleStar(messages: [Message]) async throws {
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

    // MARK: - Draft

    public func draftWithPendingAction() -> Results<Draft> {
        let realm = getRealm()
        return realm.objects(Draft.self).where { $0.action != nil }
    }

    public func draft(messageUid: String, using realm: Realm? = nil) -> Draft? {
        let realm = realm ?? getRealm()
        return realm.objects(Draft.self).where { $0.messageUid == messageUid }.first
    }

    public func draft(localUuid: String, using realm: Realm? = nil) -> Draft? {
        let realm = realm ?? getRealm()
        return realm.objects(Draft.self).where { $0.localUUID == localUuid }.first
    }

    public func draft(remoteUuid: String, using realm: Realm? = nil) -> Draft? {
        let realm = realm ?? getRealm()
        return realm.objects(Draft.self).where { $0.remoteUUID == remoteUuid }.first
    }

    public func send(draft: Draft) async throws -> SendResponse {
        do {
            let cancelableResponse = try await apiFetcher.send(mailbox: mailbox, draft: draft)
            // Once the draft has been sent, we can delete it from Realm
            try await deleteLocally(draft: draft)
            return cancelableResponse
        } catch let error as AFErrorWithContext where (200 ... 299).contains(error.request.response?.statusCode ?? 0) {
            // Status code is valid but something went wrong eg. we couldn't parse the response
            try await deleteLocally(draft: draft)
            throw error
        } catch let error as MailApiError {
            // The api returned an error
            try await deleteLocally(draft: draft)
            throw error
        }
    }

    public func save(draft: Draft) async throws {
        do {
            let saveResponse = try await apiFetcher.save(mailbox: mailbox, draft: draft)
            await backgroundRealm.execute { realm in
                // Update draft in Realm
                guard let liveDraft = realm.object(ofType: Draft.self, forPrimaryKey: draft.localUUID) else { return }
                try? realm.safeWrite {
                    liveDraft.remoteUUID = saveResponse.uuid
                    liveDraft.messageUid = saveResponse.uid
                    liveDraft.action = nil
                }
            }
        } catch let error as MailApiError {
            // The api returned an error for now we can do nothing about it so we delete the draft
            try await deleteLocally(draft: draft)
            throw error
        }
    }

    public func delete(draft: Draft) async throws {
        try await deleteLocally(draft: draft)
        try await apiFetcher.deleteDraft(mailbox: mailbox, draftId: draft.remoteUUID)
    }

    public func delete(draftMessage: Message) async throws {
        guard let draftResource = draftMessage.draftResource else {
            throw MailError.resourceError
        }

        if let draft = getRealm().objects(Draft.self).where({ $0.remoteUUID == draftResource }).first?.freeze() {
            try await deleteLocally(draft: draft)
        }

        try await apiFetcher.deleteDraft(draftResource: draftResource)
        try await refreshFolder(from: [draftMessage])
    }

    public func deleteLocally(draft: Draft) async throws {
        await backgroundRealm.execute { realm in
            guard let liveDraft = realm.object(ofType: Draft.self, forPrimaryKey: draft.localUUID) else { return }
            try? realm.safeWrite {
                realm.delete(liveDraft)
            }
        }
    }

    public func deleteOrphanDrafts() async {
        guard let draftFolder = getFolder(with: .draft) else { return }

        let existingMessageUids = Set(draftFolder.threads.flatMap(\.messages).map(\.uid))

        await backgroundRealm.execute { realm in
            try? realm.safeWrite {
                let noActionDrafts = realm.objects(Draft.self).where { $0.action == nil }
                for draft in noActionDrafts {
                    if let messageUid = draft.messageUid,
                       !existingMessageUids.contains(messageUid) {
                        realm.delete(draft)
                    }
                }
            }
        }
    }

    // MARK: - Utilities

    struct MessagePropertiesOptions: OptionSet {
        let rawValue: Int

        static let fullyDownloaded = MessagePropertiesOptions(rawValue: 1 << 0)
        static let body = MessagePropertiesOptions(rawValue: 1 << 1)
        static let attachments = MessagePropertiesOptions(rawValue: 1 << 2)
        static let localSafeDisplay = MessagePropertiesOptions(rawValue: 1 << 3)

        static let standard: MessagePropertiesOptions = [.fullyDownloaded, .body, .attachments, .localSafeDisplay]
    }

    private func keepCacheAttributes(
        for message: Message,
        keepProperties: MessagePropertiesOptions,
        using realm: Realm? = nil
    ) {
        let realm = realm ?? getRealm()
        guard let savedMessage = realm.object(ofType: Message.self, forPrimaryKey: message.uid) else { return }
        message.inTrash = savedMessage.inTrash
        if keepProperties.contains(.fullyDownloaded) {
            message.fullyDownloaded = savedMessage.fullyDownloaded
        }
        if keepProperties.contains(.body), let body = savedMessage.body {
            message.body = Body(value: body)
        }
        if keepProperties.contains(.localSafeDisplay) {
            message.localSafeDisplay = savedMessage.localSafeDisplay
        }
        if keepProperties.contains(.attachments) {
            for attachment in savedMessage.attachments {
                message.attachments.append(Attachment(value: attachment.freeze()))
            }
        }
    }

    private func keepCacheAttributes(
        for folder: Folder,
        using realm: Realm
    ) {
        guard let savedFolder = realm.object(ofType: Folder.self, forPrimaryKey: folder._id) else { return }
        folder.unreadCount = savedFolder.unreadCount
        folder.lastUpdate = savedFolder.lastUpdate
        folder.cursor = savedFolder.cursor
        folder.remainingOldMessagesToFetch = savedFolder.remainingOldMessagesToFetch
        folder.isHistoryComplete = savedFolder.isHistoryComplete
        folder.isExpanded = savedFolder.isExpanded
    }

    func getSubFolders(from folders: [Folder], oldResult: [Folder] = []) -> [Folder] {
        var result = oldResult
        for folder in folders {
            result.append(folder)
            if !folder.children.isEmpty {
                result.append(contentsOf: getSubFolders(from: Array(folder.children)))
            }
        }
        return result
    }

    public func hasUnreadMessages() -> Bool {
        let realm = getRealm()
        return realm.objects(Folder.self).contains { $0.unreadCount > 0 }
    }
}

// MARK: - Equatable conformance

extension MailboxManager: Equatable {
    public static func == (lhs: MailboxManager, rhs: MailboxManager) -> Bool {
        return lhs.mailbox.id == rhs.mailbox.id
    }
}

public extension Realm {
    func uncheckedSafeWrite(_ block: () throws -> Void) throws {
        if isInWriteTransaction {
            try block()
        } else {
            try write(block)
        }
    }

    func safeWrite(_ block: () throws -> Void) throws {
        #if DEBUG
        dispatchPrecondition(condition: .notOnQueue(.main))
        #endif

        if isInWriteTransaction {
            try block()
        } else {
            try write(block)
        }
    }
}
