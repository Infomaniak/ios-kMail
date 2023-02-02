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
import MailResources
import RealmSwift
import Sentry
import SwiftRegex

public class MailboxManager: ObservableObject {
    public class MailboxManagerConstants {
        private let fileManager = FileManager.default
        public let rootDocumentsURL: URL
        public let groupDirectoryURL: URL
        public let cacheDirectoryURL: URL

        init() {
            groupDirectoryURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: AccountManager.appGroup)!
            rootDocumentsURL = groupDirectoryURL.appendingPathComponent("mailboxes", isDirectory: true)
            cacheDirectoryURL = groupDirectoryURL.appendingPathComponent("Library/Caches", isDirectory: true)
            print(groupDirectoryURL)
            try? fileManager.setAttributes(
                [FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: groupDirectoryURL.path
            )
            try? FileManager.default.createDirectory(
                atPath: rootDocumentsURL.path,
                withIntermediateDirectories: true,
                attributes: nil
            )
            try? FileManager.default.createDirectory(
                atPath: cacheDirectoryURL.path,
                withIntermediateDirectories: true,
                attributes: nil
            )

            DDLogInfo(
                "App working path is: \(fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.absoluteString ?? "")"
            )
            DDLogInfo("Group container path is: \(groupDirectoryURL.absoluteString)")
        }
    }

    public static let constants = MailboxManagerConstants()

    public let realmConfiguration: Realm.Configuration
    public let mailbox: Mailbox
    public private(set) var apiFetcher: MailApiFetcher
    private let backgroundRealm: BackgroundRealm

    public init(mailbox: Mailbox, apiFetcher: MailApiFetcher) {
        self.mailbox = mailbox
        self.apiFetcher = apiFetcher
        let realmName = "\(mailbox.userId)-\(mailbox.mailboxId).realm"
        realmConfiguration = Realm.Configuration(
            fileURL: MailboxManager.constants.rootDocumentsURL.appendingPathComponent(realmName),
            schemaVersion: 5,
            deleteRealmIfMigrationNeeded: true,
            objectTypes: [
                Folder.self,
                Thread.self,
                Message.self,
                Body.self,
                Attachment.self,
                Recipient.self,
                Draft.self,
                SignatureResponse.self,
                Signature.self,
                ValidEmail.self,
                SearchHistory.self
            ]
        )
        backgroundRealm = BackgroundRealm(configuration: realmConfiguration)
    }

    public func getRealm() -> Realm {
        do {
            return try Realm(configuration: realmConfiguration)
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

    public func signatures() async throws {
        // Get from API
        let signaturesResult = try await apiFetcher.signatures(mailbox: mailbox)

        await backgroundRealm.execute { realm in
            // Update signatures in Realm
            try? realm.safeWrite {
                realm.add(signaturesResult, update: .modified)
            }
        }
    }

    public func getSignatureResponse(using realm: Realm? = nil) -> SignatureResponse? {
        let realm = realm ?? getRealm()
        return realm.object(ofType: SignatureResponse.self, forPrimaryKey: 1)
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
                let toDeleteFolders = Set(cachedFolders).subtracting(Set(newFolders))
                var toDeleteThreads = [Thread]()

                // Threads contains in folders to delete
                let mayBeDeletedThreads = Set(toDeleteFolders.flatMap(\.threads))
                // Delete messages in all threads from folders to delete
                // If message.folderId is one of folders to delete Id
                let toDeleteMessages = Set(mayBeDeletedThreads.flatMap(\.messages)
                    .filter { toDeleteFolders.map(\._id).contains($0.folderId) })

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
    ///   - shouldRefresh: If `true`, the Realm instance will be refreshed before trying to get the folder.
    /// - Returns: The folder with the corresponding role, or `nil` if no such folder has been found.
    public func getFolder(with role: FolderRole, using realm: Realm? = nil, shouldRefresh: Bool = false) -> Folder? {
        let realm = realm ?? getRealm()
        if shouldRefresh {
            realm.refresh()
        }
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
                if let parent = parent {
                    parent.fresh(using: realm)?.children.insert(folder)
                }
            }
            folder = folder.freeze()
        }
        return folder
    }

    private func refreshFolder(from messages: [Message], additionalFolderId: String? = nil) async throws {
        var foldersId = messages.map(\.folderId)
        if let additionalFolderId = additionalFolderId {
            foldersId.append(additionalFolderId)
        }

        let orderedSet = NSOrderedSet(array: foldersId)

        for id in orderedSet {
            let realm = getRealm()
            if let impactedFolder = realm.object(ofType: Folder.self, forPrimaryKey: id) {
                try await threads(folder: impactedFolder)
            }
        }
    }

    // MARK: - Thread

    public func threads(folder: Folder) async throws {
        let alwaysFetchedFolders: [FolderRole] = [.inbox, .sent, .draft]

        if alwaysFetchedFolders.contains(where: { $0 == folder.role }) {
            for folderRole in alwaysFetchedFolders {
                if let realFolder = getFolder(with: folderRole) {
                    try await messages(folder: realFolder.freezeIfNeeded())
                }
            }
        } else {
            try await messages(folder: folder.freezeIfNeeded())
        }
    }

    private func deleteMessages(uids: [String], folder: Folder) async {
        guard !uids.isEmpty else { return }

        await backgroundRealm.execute { realm in
            let messagesToDelete = realm.objects(Message.self).where { $0.uid.in(uids) }
            var threadsToUpdate = Set<Thread>()
            var threadsToDelete = Set<Thread>()
            var draftsToDelete = Set<Draft>()

            for message in messagesToDelete {
                if let draft = self.draft(messageUid: message.uid, using: realm) {
                    draftsToDelete.insert(draft)
                }
                for parent in message.parents {
                    threadsToUpdate.insert(parent)
                }
            }

            let foldersToUpdate = Set(threadsToUpdate.compactMap(\.parent))

            try? realm.safeWrite {
                realm.delete(draftsToDelete)
                realm.delete(messagesToDelete)
                for thread in threadsToUpdate {
                    if thread.messageInFolderCount == 0 {
                        threadsToDelete.insert(thread)
                    } else {
                        thread.recompute()
                    }
                }
                realm.delete(threadsToDelete)
                for updateFolder in foldersToUpdate {
                    updateFolder.computeUnreadCount()
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
            var messages = threads.compactMap { thread in
                thread.messages.last { $0.isDraft == false }
            }
            messages.append(contentsOf: messages.flatMap(\.duplicates))
            try await markAsSeen(messages: messages, seen: false)
        }
    }

    public func move(threads: [Thread], to folderRole: FolderRole) async throws -> UndoRedoAction {
        guard let folder = getFolder(with: folderRole)?.freeze() else { throw MailError.folderNotFound }
        return try await move(threads: threads, to: folder)
    }

    public func move(threads: [Thread], to folder: Folder) async throws -> UndoRedoAction {
        var messages = threads.flatMap(\.messages).filter { $0.folderId == threads.first?.folderId }
        messages.append(contentsOf: messages.flatMap(\.duplicates))

        return try await move(messages: messages, to: folder)
    }

    /// Move to trash or delete threads, depending on its current state
    /// - Parameter threads: Threads to remove
    public func moveOrDelete(threads: [Thread]) async throws {
        // All threads comes from the same folder
        guard let parentFolder = threads.first?.parent else { return }

        if parentFolder.toolType == .search {
            for thread in threads {
                await deleteInSearch(thread: thread) // Review this ?
            }
        }

        if parentFolder.role == .trash || parentFolder.role == .draft || parentFolder.role == .spam {
            var messages = threads.flatMap(\.messages)
            messages.append(contentsOf: messages.flatMap(\.duplicates))
            try await delete(messages: messages)
        } else {
            var messages = threads.flatMap(\.messages).filter { $0.scheduled == false }
            messages.append(contentsOf: messages.flatMap(\.duplicates))
            let undoRedoAction = try await move(messages: messages, to: .trash)
            let folderName = FolderRole.trash.localizedName
            Task.detached {
                await IKSnackBar.showCancelableSnackBar(message: MailResourcesStrings.Localizable.snackbarThreadMoved(folderName),
                                                        cancelSuccessMessage: MailResourcesStrings.Localizable
                                                            .snackbarMoveCancelled,
                                                        undoRedoAction: undoRedoAction,
                                                        mailboxManager: self)
            }
        }
    }

    private func deleteInSearch(thread: Thread) async {
        await backgroundRealm.execute { realm in
            guard let searchFolder = realm.object(ofType: Folder.self, forPrimaryKey: Constants.searchFolderId),
                  let thread = thread.fresh(using: realm) else { return }

            try? realm.safeWrite {
                searchFolder.threads.remove(thread)
            }
        }
    }

    public func toggleStar(threads: [Thread]) async throws {
        if threads.contains(where: { !$0.flagged }) {
            var messages = threads.compactMap { thread in
                thread.messages.last { $0.isDraft == false }
            }
            messages.append(contentsOf: messages.flatMap(\.duplicates))
            _ = try await star(messages: messages)
        } else {
            var messages = threads.flatMap { thread in
                thread.messages.where { $0.isDraft == false }
            }
            messages.append(contentsOf: messages.flatMap(\.duplicates))
            _ = try await unstar(messages: messages)
        }
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
            searchFilter: searchFilter
        )

        await backgroundRealm.execute { realm in
            for thread in threadResult.threads ?? [] {
                thread.fromSearch = true

                for message in thread.messages where realm.object(ofType: Message.self, forPrimaryKey: message.uid) == nil {
                    message.fromSearch = true
                }
            }
        }

        if let searchFolder = searchFolder {
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

        if let searchFolder = searchFolder {
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
                case let .filter(filter):
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
                case let .from(from):
                    predicates.append(NSPredicate(format: "ANY from.email = %@", from))
                case let .contains(content):
                    predicates
                        .append(NSPredicate(format: "body.value CONTAINS %@ OR subject CONTAINS %@", content, content))
                case let .everywhere(searchEverywhere):
                    if !searchEverywhere {
                        predicates.append(NSPredicate(format: "folderId = %@", filterFolderId))
                    }
                case let .attachments(searchAttachments):
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
                        messagesCount: 1,
                        deletedMessagesCount: 0,
                        messages: [newMessage],
                        unseenMessages: 0,
                        from: Array(message.from.detached()),
                        to: Array(message.to.detached()),
                        cc: Array(message.cc.detached()),
                        bcc: Array(message.bcc.detached()),
                        date: newMessage.date,
                        hasAttachments: newMessage.hasAttachments,
                        hasSwissTransferAttachments: newMessage.hasAttachments,
                        hasDrafts: newMessage.isDraft,
                        flagged: newMessage.flagged,
                        answered: newMessage.answered,
                        forwarded: newMessage.forwarded,
                        size: newMessage.size
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

    private func getUniqueUidsInReverse(folder: Folder, remoteUids: [String]) -> [String] {
        let localUids = Set(folder.threads.map { Constants.shortUid(from: $0.uid) })
        let remoteUidsSet = Set(remoteUids)
        var uniqueUids: Set<String> = Set()
        if localUids.isEmpty {
            uniqueUids = remoteUidsSet
        } else {
            uniqueUids = remoteUidsSet.subtracting(localUids)
        }
        return uniqueUids.reversed()
    }

    public func messages(folder: Folder) async throws {
        let previousCursor = folder.cursor
        var newCursor: String?

        var deletedUids = [String]()
        var addedShortUids = [String]()
        var updated = [MessageFlags]()

        if previousCursor == nil {
            let messageUidsResult = try await apiFetcher.messagesUids(
                mailboxUuid: mailbox.uuid,
                folderId: folder.id
            )
            newCursor = messageUidsResult.cursor
            addedShortUids.append(contentsOf: messageUidsResult.messageShortUids.map { String($0) })
        } else {
            let messageDeltaResult = try await apiFetcher.messagesDelta(
                mailboxUUid: mailbox.uuid,
                folderId: folder.id,
                signature: previousCursor!
            )
            newCursor = messageDeltaResult.cursor
            deletedUids
                .append(contentsOf: messageDeltaResult.deletedShortUids
                    .map { Constants.longUid(from: String($0), folderId: folder.id) })
            addedShortUids.append(contentsOf: messageDeltaResult.addedShortUids)
            updated.append(contentsOf: messageDeltaResult.updated)
        }

        try await addMessages(shortUids: addedShortUids, folder: folder)
        await deleteMessages(uids: deletedUids, folder: folder)
        await updateMessages(updates: updated, folder: folder)

        await backgroundRealm.execute { [self] realm in
            if newCursor != nil {
                guard let folder = folder.fresh(using: realm) else { return }
                try? realm.safeWrite {
                    folder.computeUnreadCount()
                    folder.cursor = newCursor
                    folder.lastUpdate = Date()
                }
            }

            searchForOrphanMessages(folderId: folder.id, using: realm)
            searchForOrphanThreads(using: realm)
        }

        if folder.role == .inbox {
            MailboxInfosManager.instance.updateUnseen(unseenMessages: folder.unreadCount, for: mailbox)
        }
    }

    private func searchForOrphanMessages(folderId: String, using realm: Realm? = nil) {
        let realm = realm ?? getRealm()
        let orphanMessages = realm.objects(Message.self).where { $0.folderId == folderId }.filter { $0.parents.isEmpty }
        if !orphanMessages.isEmpty {
            SentrySDK.capture(message: "We found some orphan Messages.") { scope in
                scope.setLevel(.error)
                scope.setContext(value: ["uids": "\(orphanMessages.map { $0.uid })"], key: "orphanMessages")
            }
        }
    }

    private func searchForOrphanThreads(using realm: Realm? = nil) {
        let realm = realm ?? getRealm()
        let orphanThreads = realm.objects(Thread.self).filter { $0.parentLink.isEmpty }
        if !orphanThreads.isEmpty {
            SentrySDK.capture(message: "We found some orphan Threads.") { scope in
                scope.setLevel(.error)
                scope.setContext(value: ["uids": "\(orphanThreads.map { $0.uid })"], key: "orphanThreads")
            }
        }
    }

    private func addMessages(shortUids: [String], folder: Folder) async throws {
        guard !shortUids.isEmpty else { return }
        let reversedUids: [String] = getUniqueUidsInReverse(folder: folder, remoteUids: shortUids)
        let pageSize = 50
        var offset = 0
        while offset < reversedUids.count {
            let end = min(offset + pageSize, reversedUids.count)
            let newList = Array(reversedUids[offset ..< end])
            let messageByUidsResult = try await apiFetcher.messagesByUids(
                mailboxUuid: mailbox.uuid,
                folderId: folder.id,
                messageUids: newList
            )

            await backgroundRealm.execute { [self] realm in
                if let folder = folder.fresh(using: realm) {
                    createMultiMessagesThreads(messageByUids: messageByUidsResult, folder: folder, using: realm)
                }
            }

            sendMissingMessagesSentry(sentUids: newList, receivedMessages: messageByUidsResult.messages, folderId: folder.id)

            offset += pageSize
        }
    }

    private func sendMissingMessagesSentry(sentUids: [String], receivedMessages: [Message], folderId: String) {
        if receivedMessages.count != sentUids.count {
            let receivedUids = Set(receivedMessages.map { Constants.shortUid(from: $0.uid) })
            let missingUids = sentUids.filter { !receivedUids.contains($0) }
            if !missingUids.isEmpty {
                SentrySDK.capture(message: "We tried to download some Messages, but they were nowhere to be found") { scope in
                    scope.setLevel(.error)
                    scope.setContext(
                        value: ["uids": "\(missingUids.map { Constants.longUid(from: $0, folderId: folderId) })"],
                        key: "missingMessages"
                    )
                }
            }
        }
    }

    private func createMultiMessagesThreads(messageByUids: MessageByUidsResult, folder: Folder, using realm: Realm) {
        var threadsToUpdate = Set<Thread>()
        try? realm.safeWrite {
            for message in messageByUids.messages {
                if realm.object(ofType: Message.self, forPrimaryKey: message.uid) == nil {
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

                    for thread in existingThreads {
                        thread.addMessageIfNeeded(newMessage: message.fresh(using: realm) ?? message)
                        threadsToUpdate.insert(thread)
                    }
                }
            }
            self.updateThreads(threads: threadsToUpdate)
        }
    }

    private func createNewThreadIfRequired(for message: Message, folder: Folder, existingThreads: [Thread]) -> Thread? {
        guard !existingThreads.contains(where: { $0.folderId == folder.id }) else { return nil }

        let thread = message.toThread().detached()
        folder.threads.insert(thread)

        if let refThread = existingThreads.first(where: { $0.parent?.role != .draft && $0.parent?.role != .trash }) {
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

                        for parent in message.parents {
                            threadsToUpdate.insert(parent)
                        }
                    }
                }
                self.updateThreads(threads: threadsToUpdate)
            }
        }
    }

    private func updateThreads(threads: Set<Thread>) {
        let folders = Set(threads.compactMap(\.parent))
        for thread in threads {
            thread.recompute()
        }
        for folder in folders {
            folder.computeUnreadCount()
        }
    }

    public func message(message: Message) async throws {
        // Get from API
        let completedMessage = try await apiFetcher.message(message: message)
        completedMessage.insertInlineAttachment()
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

    /// Move to trash or delete message, depending on its current state
    /// - Parameter message: Message to remove
    public func moveOrDelete(message: Message) async throws {
        if message.folderId == getFolder(with: .trash)?._id
            || message.folderId == getFolder(with: .spam)?._id
            || message.folderId == getFolder(with: .draft)?._id {
            var messages = [message]
            messages.append(contentsOf: message.duplicates)
            try await delete(messages: messages)
        } else {
            var messages = [message]
            messages.append(contentsOf: message.duplicates)
            let undoRedoAction = try await move(messages: messages, to: .trash)
            Task.detached {
                await IKSnackBar.showCancelableSnackBar(
                    message: MailResourcesStrings.Localizable.snackbarMessageMoved(FolderRole.trash.localizedName),
                    cancelSuccessMessage: MailResourcesStrings.Localizable.snackbarMoveCancelled,
                    undoRedoAction: undoRedoAction,
                    mailboxManager: self
                )
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
    }

    public func move(messages: [Message], to folderRole: FolderRole) async throws -> UndoRedoAction {
        guard let folder = getFolder(with: folderRole)?.freeze() else { throw MailError.folderNotFound }
        return try await move(messages: messages, to: folder)
    }

    public func move(messages: [Message], to folder: Folder) async throws -> UndoRedoAction {
        let response = try await apiFetcher.move(mailbox: mailbox, messages: messages, destinationId: folder._id)
        try await refreshFolder(from: messages, additionalFolderId: folder.id)
        return undoRedoAction(for: response, and: messages)
    }

    public func delete(messages: [Message]) async throws {
        _ = try await apiFetcher.delete(mailbox: mailbox, messages: messages)
        try await refreshFolder(from: messages)
    }

    public func star(messages: [Message]) async throws -> MessageActionResult {
        let response = try await apiFetcher.star(mailbox: mailbox, messages: messages)
        try await refreshFolder(from: messages)
        return response
    }

    public func unstar(messages: [Message]) async throws -> MessageActionResult {
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
        realm.refresh()
        return realm.objects(Draft.self).where { $0.action != nil }
    }

    public func draft(partialDraft: Draft) async throws -> Draft? {
        guard let associatedMessage = getRealm().object(ofType: Message.self, forPrimaryKey: partialDraft.messageUid)?.freeze()
        else { return nil }

        // Get from API
        let draft = try await apiFetcher.draft(from: associatedMessage)

        await backgroundRealm.execute { realm in
            draft.localUUID = partialDraft.localUUID
            draft.action = .save
            draft.identityId = partialDraft.identityId
            draft.delay = partialDraft.delay

            try? realm.safeWrite {
                realm.add(draft.detached(), update: .modified)
            }
        }

        return getRealm().object(ofType: Draft.self, forPrimaryKey: draft.localUUID)?.freeze()
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
        let cancelableResponse = try await apiFetcher.send(mailbox: mailbox, draft: draft)
        // Once the draft has been sent, we can delete it from Realm
        try await deleteLocally(draft: draft)
        return cancelableResponse
    }

    public func save(draft: Draft) async throws {
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
        guard let draftFolder = getFolder(with: .draft, shouldRefresh: true) else { return }

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

        static let standard: MessagePropertiesOptions = [.fullyDownloaded, .body, .attachments]
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
