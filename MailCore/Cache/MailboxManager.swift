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
            schemaVersion: 1,
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

    // MARK: - Thread

    private func deleteMessagesThread(uids: [String]) async {
        if !uids.isEmpty {
            await backgroundRealm.execute { realm in
                let messagesToDelete = realm.objects(Message.self).where { $0.uid.in(uids) }
                var threadsToDelete = [Thread]()
                var threadsToUpdate = [Thread]()
                for message in messagesToDelete {
                    if let thread = message.parent {
                        if thread.messageIds.count <= 1 {
                            threadsToDelete.append(thread)
                        } else {
                            threadsToUpdate.append(thread)
                        }
                    }
                }

                try? realm.safeWrite {
                    realm.delete(messagesToDelete)
                    realm.delete(threadsToDelete)
                    for update in threadsToUpdate {
                        update.recompute()
                    }
                }
            }
        }
    }

    public func threads(folder: Folder, filter: Filter = .all, searchFilter: [URLQueryItem] = []) async throws -> ThreadResult {
        // Get from API
        let threadResult = try await apiFetcher.threads(
            mailbox: mailbox,
            folderId: folder._id,
            filter: filter,
            searchFilter: searchFilter
        )

        // Save result
        await saveThreads(result: threadResult, parent: folder)

        return threadResult
    }

    public func threads(folder: Folder, resource: String) async throws -> ThreadResult {
        // Get from API
        let threadResult = try await apiFetcher.threads(from: resource)

        // Save result
        await saveThreads(result: threadResult, parent: folder)

        return threadResult
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
                    realm.delete(parentFolder.threads.flatMap(\.messages))
                    realm.delete(parentFolder.threads)
                }
                realm.add(fetchedThreads, update: .modified)
                parentFolder.threads.insert(objectsIn: fetchedThreads)
                parentFolder.unreadCount = result.folderUnseenMessages
            }
        }
    }

    public func toggleRead(threads: [Thread]) async throws {
        if threads.contains(where: \.hasUnseenMessages) {
            _ = try await apiFetcher.markAsSeen(mailbox: mailbox, messages: threads.flatMap(\.messages))
            await backgroundRealm.execute { realm in
                for thread in threads {
                    self.markAsSeen(thread: thread, using: realm)
                }
            }
        } else {
            _ = try await apiFetcher.markAsUnseen(mailbox: mailbox, messages: threads.flatMap(\.messages))
            await backgroundRealm.execute { realm in
                for thread in threads {
                    self.markAsUnseen(thread: thread, using: realm)
                }
            }
        }
    }

    public func toggleRead(thread: Thread) async throws {
        if thread.hasUnseenMessages {
            _ = try await apiFetcher.markAsSeen(mailbox: mailbox, messages: Array(thread.messages))
            await backgroundRealm.execute { realm in
                self.markAsSeen(thread: thread, using: realm)
            }
        } else {
            _ = try await apiFetcher.markAsUnseen(mailbox: mailbox, messages: Array(thread.messages))
            await backgroundRealm.execute { realm in
                self.markAsUnseen(thread: thread, using: realm)
            }
        }
    }

    public func move(threads: [Thread], to folder: Folder) async throws -> UndoRedoAction {
        let response = try await apiFetcher.move(
            mailbox: mailbox,
            messages: threads.flatMap(\.messages),
            destinationId: folder._id
        )

        let redoBlock = await backgroundRealm.execute { realm in
            if let liveFolder = folder.fresh(using: realm) {
                let liveThreads = threads.compactMap { $0.fresh(using: realm) }
                return try? self.moveLocally(threads: liveThreads, to: liveFolder, using: realm)
            } else {
                return nil
            }
        }

        return UndoRedoAction(undo: response, redo: redoBlock)
    }

    public func move(thread: Thread, to folder: Folder) async throws -> UndoRedoAction {
        let response = try await apiFetcher.move(mailbox: mailbox, messages: Array(thread.messages), destinationId: folder._id)

        let redoBlock = await backgroundRealm.execute { realm in
            if let liveFolder = folder.fresh(using: realm),
               let liveThread = thread.fresh(using: realm) {
                return try? self.moveLocally(threads: [liveThread], to: liveFolder, using: realm)
            } else {
                return nil
            }
        }

        return UndoRedoAction(undo: response, redo: redoBlock)
    }

    public func move(threads: [Thread], to folderRole: FolderRole) async throws -> UndoRedoAction {
        guard let folder = getFolder(with: folderRole)?.freeze() else { throw MailError.folderNotFound }
        return try await move(threads: threads, to: folder)
    }

    public func move(thread: Thread, to folderRole: FolderRole) async throws -> UndoRedoAction {
        guard let folder = getFolder(with: folderRole)?.freeze() else { throw MailError.folderNotFound }
        return try await move(thread: thread, to: folder)
    }

    public func delete(threads: [Thread]) async throws {
        _ = try await apiFetcher.delete(mailbox: mailbox, messages: threads.flatMap(\.messages))

        await backgroundRealm.execute { realm in
            for thread in threads {
                if let liveThread = thread.fresh(using: realm) {
                    try? realm.safeWrite {
                        liveThread.parent?.unreadCount = (liveThread.parent?.unreadCount ?? 0) - liveThread.unseenMessages
                        realm.delete(liveThread.messages)
                        realm.delete(liveThread)
                    }
                }
            }
        }
    }

    public func delete(thread: Thread) async throws {
        _ = try await apiFetcher.delete(mailbox: mailbox, messages: Array(thread.messages))

        await backgroundRealm.execute { realm in
            if let liveThread = thread.fresh(using: realm) {
                try? realm.safeWrite {
                    liveThread.parent?.unreadCount = (liveThread.parent?.unreadCount ?? 0) - liveThread.unseenMessages
                    realm.delete(liveThread.messages)
                    realm.delete(liveThread)
                }
            }
        }
    }

    public func moveOrDelete(threads: [Thread]) async throws {
        let draftThreads = threads.filter(\.isLocalDraft)
        for draft in draftThreads {
            await deleteLocalDraft(thread: draft)
        }

        let otherThreads = threads.filter { !$0.isLocalDraft }
        let parentFolder = otherThreads.first?.parent
        if parentFolder?.role == .trash {
            try await delete(threads: otherThreads)
        } else {
            let undoRedoAction = try await move(threads: threads, to: .trash)
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

    /// Move to trash or delete thread, depending on its current state
    /// - Parameter thread: Thread to remove
    public func moveOrDelete(thread: Thread) async throws {
        let parentFolder = thread.parent
        if parentFolder?.toolType == nil {
            await deleteInSearch(thread: thread)
        }
        if parentFolder?.role == .trash {
            // Delete definitely
            try await delete(thread: thread)
        } else if thread.isLocalDraft {
            // Delete local draft from Realm
            await deleteLocalDraft(thread: thread)
        } else {
            // Move to trash
            let response = try await move(thread: thread, to: .trash)
            let folderName = FolderRole.trash.localizedName
            Task.detached {
                await IKSnackBar.showCancelableSnackBar(message: MailResourcesStrings.Localizable.snackbarThreadMoved(folderName),
                                                        cancelSuccessMessage: MailResourcesStrings.Localizable
                                                            .snackbarMoveCancelled,
                                                        undoRedoAction: response,
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

    public func reportSpam(threads: [Thread]) async throws -> UndoRedoAction {
        let response = try await apiFetcher.reportSpam(mailbox: mailbox, messages: threads.flatMap(\.messages))
        let redoBlock = await backgroundRealm.execute { realm in
            if let spamFolder = self.getFolder(with: .spam, using: realm) {
                let liveThreads = threads.compactMap { $0.fresh(using: realm) }
                return try? self.moveLocally(threads: liveThreads, to: spamFolder, using: realm)
            } else {
                return nil
            }
        }

        return UndoRedoAction(undo: response, redo: redoBlock)
    }

    public func reportSpam(thread: Thread) async throws -> UndoRedoAction {
        let response = try await apiFetcher.reportSpam(mailbox: mailbox, messages: Array(thread.messages))
        let redoBlock = await backgroundRealm.execute { realm in
            if let spamFolder = self.getFolder(with: .spam, using: realm),
               let liveThread = thread.fresh(using: realm) {
                return try? self.moveLocally(threads: [liveThread], to: spamFolder, using: realm)
            } else {
                return nil
            }
        }

        return UndoRedoAction(undo: response, redo: redoBlock)
    }

    public func nonSpam(threads: [Thread]) async throws -> UndoRedoAction {
        let response = try await apiFetcher.nonSpam(mailbox: mailbox, messages: threads.flatMap(\.messages))
        let redoBlock = await backgroundRealm.execute { realm in
            if let inboxFolder = self.getFolder(with: .inbox, using: realm) {
                let liveThreads = threads.compactMap { $0.fresh(using: realm) }
                return try? self.moveLocally(threads: liveThreads, to: inboxFolder, using: realm)
            } else {
                return nil
            }
        }

        return UndoRedoAction(undo: response, redo: redoBlock)
    }

    public func nonSpam(thread: Thread) async throws -> UndoRedoAction {
        let response = try await apiFetcher.nonSpam(mailbox: mailbox, messages: Array(thread.messages))
        let redoBlock = await backgroundRealm.execute { realm in
            if let inboxFolder = self.getFolder(with: .inbox, using: realm),
               let liveThread = thread.fresh(using: realm) {
                return try? self.moveLocally(threads: [liveThread], to: inboxFolder, using: realm)
            } else {
                return nil
            }
        }

        return UndoRedoAction(undo: response, redo: redoBlock)
    }

    public func toggleStar(threads: [Thread]) async throws {
        if threads.contains(where: { !$0.flagged }) {
            _ = try await apiFetcher.star(mailbox: mailbox, messages: threads.flatMap(\.messages))
            await backgroundRealm.execute { realm in
                for thread in threads {
                    self.star(thread: thread, using: realm)
                }
            }
        } else {
            _ = try await apiFetcher.unstar(mailbox: mailbox, messages: threads.flatMap(\.messages))
            await backgroundRealm.execute { realm in
                for thread in threads {
                    self.unstar(thread: thread, using: realm)
                }
            }
        }
    }

    public func toggleStar(thread: Thread) async throws {
        if thread.flagged {
            _ = try await apiFetcher.unstar(mailbox: mailbox, messages: Array(thread.messages))
            await backgroundRealm.execute { realm in
                self.unstar(thread: thread, using: realm)
            }
        } else {
            guard let lastMessage = thread.messages.last else { return }
            _ = try await apiFetcher.star(mailbox: mailbox, messages: [lastMessage])
            await backgroundRealm.execute { realm in
                self.star(thread: thread, using: realm)
            }
        }
    }

    @discardableResult
    private func moveLocally(threads: [Thread], to folder: Folder, using realm: Realm) throws -> UndoRedoAction.RedoBlock {
        let previousFolders = threads.compactMap { $0.parent?.freeze() }

        try realm.safeWrite {
            for thread in threads {
                thread.parent?.unreadCount = (thread.parent?.unreadCount ?? 0) - thread.unseenMessages
                thread.parent?.threads.remove(thread)
                folder.threads.insert(thread)
                folder.unreadCount = (folder.unreadCount ?? 0) + thread.unseenMessages
                for message in thread.messages {
                    message.folder = folder.name
                    message.folderId = folder._id
                }
            }
        }

        return { [weak self] in
            // Try to do only one API call if possible
            // FIXME: This is only a temporary solution
            if previousFolders.allSatisfy({ $0._id == previousFolders.first?._id }),
               let previousFolder = previousFolders.first {
                _ = try await self?.threads(folder: previousFolder)
            } else {
                await withThrowingTaskGroup(of: Void.self) { group in
                    for previousFolder in previousFolders {
                        group.addTask { [weak self] in
                            _ = try await self?.threads(folder: previousFolder)
                        }
                    }
                }
            }
        }
    }

    private func markAsSeen(thread: Thread, using realm: Realm) {
        guard let liveThread = thread.fresh(using: realm) else { return }
        try? realm.safeWrite {
            liveThread.parent?.unreadCount = (liveThread.parent?.unreadCount ?? 0) - liveThread.unseenMessages
            liveThread.unseenMessages = 0
            for message in liveThread.messages {
                message.seen = true
            }
        }
    }

    private func markAsUnseen(thread: Thread, using realm: Realm) {
        guard let liveThread = thread.fresh(using: realm) else { return }
        try? realm.safeWrite {
            liveThread.unseenMessages = liveThread.messagesCount
            liveThread.parent?.unreadCount = (liveThread.parent?.unreadCount ?? 0) + liveThread.unseenMessages
            for message in liveThread.messages {
                message.seen = false
            }
        }
    }

    private func star(thread: Thread, using realm: Realm) {
        guard let lastMessage = thread.messages.last else { return }
        if let liveThread = thread.fresh(using: realm) {
            try? realm.safeWrite {
                liveThread.flagged = true
                lastMessage.fresh(using: realm)?.flagged = true
            }
        }
    }

    private func unstar(thread: Thread, using realm: Realm) {
        if let liveThread = thread.fresh(using: realm) {
            try? realm.safeWrite {
                liveThread.flagged = false
                for message in thread.messages {
                    message.fresh(using: realm)?.flagged = false
                }
            }
        }
    }

    // MARK: - Search

    public func initSearchFolder() -> Folder {
        let searchFolder = Folder(
            id: Constants.searchFolderId,
            path: "",
            name: "",
            isFake: false,
            isCollapsed: false,
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
            for thread in threadResult.threads ?? [] where realm.object(ofType: Thread.self, forPrimaryKey: thread.uid) == nil {
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
        for thread in threadResult.threads ?? [] where realm.object(ofType: Thread.self, forPrimaryKey: thread.uid) == nil {
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
                        uniqueMessagesCount: 1,
                        deletedMessagesCount: 0,
                        messages: [newMessage],
                        unseenMessages: 0,
                        from: Array(message.from.detached()),
                        to: Array(message.to.detached()),
                        cc: Array(message.cc.detached()),
                        bcc: Array(message.bcc.detached()),
                        date: newMessage.date,
                        hasAttachments: newMessage.hasAttachments,
                        hasStAttachments: newMessage.hasAttachments,
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
        var localUids = Set(folder.threads.map { self.shortUid(from: $0.uid) })
        var uniqueUids: Set<String> = Set()
        var remoteUidsSet = Set(remoteUids)
        if localUids.isEmpty {
            uniqueUids = remoteUidsSet
        } else {
            uniqueUids = remoteUidsSet.subtracting(localUids.intersection(remoteUidsSet))
        }
        return uniqueUids.reversed()
    }

    private func dateSince() -> String {
        var dateComponents = DateComponents()
        dateComponents.month = -3

        let dateformat = DateFormatter()
        dateformat.dateFormat = "yyyyMMdd"

        guard let date = Calendar.current.date(byAdding: dateComponents, to: Date())
        else { return dateformat.string(from: Date()) }

        return dateformat.string(from: date)
    }

    private func longUid(from shortUid: String, folderId: String) -> String {
        return "\(shortUid)@\(folderId)"
    }

    private func shortUid(from longUid: String) -> String {
        return longUid.components(separatedBy: "@")[0]
    }

    public func messages(folder: Folder, asThread: Bool = false) async throws {
        let previousCursor = folder.cursor
        var newCursor: String?

        var deletedUids = [String]()
        var addedShortUids = [String]()
        var updated = [MessageFlags]()

        if previousCursor == nil {
            let messageUidsResult = try await apiFetcher.messagesUids(
                mailboxUuid: mailbox.uuid,
                folderId: folder.id,
                dateSince: dateSince()
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
                .append(contentsOf: messageDeltaResult.deletedShortUids.map { longUid(from: String($0), folderId: folder.id) })
            addedShortUids.append(contentsOf: messageDeltaResult.addedShortUids)
            updated.append(contentsOf: messageDeltaResult.updated)
        }

        try await addMessages(shortUids: addedShortUids, folder: folder, asThread: asThread)
        if asThread {
            await deleteMessagesThread(uids: deletedUids)
        } else {
            await deleteMessages(uids: deletedUids)
        }
        await updateMessages(updates: updated, folder: folder)

        await backgroundRealm.execute { realm in
            if newCursor != nil {
                guard let folder = folder.fresh(using: realm) else { return }
                try? realm.safeWrite {
                    folder.cursor = newCursor
                }
            }
        }
    }

    private func addMessages(shortUids: [String], folder: Folder, asThread: Bool = false) async throws {
        if !shortUids.isEmpty {
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

                await backgroundRealm.execute { realm in
                    if let folder = folder.fresh(using: realm) {
                        if asThread {
                            var threadsToUpdate = Set<Thread>()
                            try? realm.safeWrite {
                                for message in messageByUidsResult.messages {
                                    message.computeReference()
                                    message.inTrash = folder.role == .trash
                                    if let thread = realm.objects(Thread.self).first(where: { value in
                                        value.messageIds.detached().contains { message.linkedUids.detached().contains($0) }
                                    }) {
                                        thread.messages.append(message)
                                        thread.messageIds.insert(objectsIn: message.linkedUids)
                                        folder.threads.insert(thread)
                                        threadsToUpdate.insert(thread)
                                    } else {
                                        let thread = message.toThread().detached()
                                        thread.messageIds.insert(objectsIn: message.linkedUids)
                                        folder.threads.insert(thread)
                                        threadsToUpdate.insert(thread)
                                    }
                                }
                                for thread in threadsToUpdate {
                                    thread.recompute()
                                }
                            }

                        } else {
                            try? realm.safeWrite {
                                let threads = messageByUidsResult.messages.map { $0.toThread().detached() }
                                folder.threads.insert(objectsIn: threads)
                            }
                        }
                    }
                }

                offset += pageSize
            }
        }
    }

    private func deleteMessages(uids: [String]) async {
        if !uids.isEmpty {
            await backgroundRealm.execute { realm in
                let messagesToDelete = realm.objects(Message.self).where { $0.uid.in(uids) }
                let threadsToDelete = realm.objects(Thread.self).where { $0.uid.in(uids) }
                try? realm.safeWrite {
                    realm.delete(messagesToDelete)
                    realm.delete(threadsToDelete)
                }
            }
        }
    }

    private func updateMessages(updates: [MessageFlags], folder: Folder) async {
        await backgroundRealm.execute { realm in
            for update in updates {
                let uid = self.longUid(from: String(update.shortUid), folderId: folder.id)
                if let message = realm.object(ofType: Message.self, forPrimaryKey: uid), let thread = message.parent {
                    try? realm.safeWrite {
                        message.answered = update.answered
                        message.flagged = update.isFavorite
                        message.forwarded = update.forwarded
                        message.scheduled = update.scheduled
                        message.seen = update.seen

                        thread.recompute()
                    }
                }
            }
        }
    }

    public func message(message: Message) async throws {
        // Get from API
        let completedMessage = try await apiFetcher.message(message: message)
        completedMessage.insertInlineAttachment()
        keepCacheAttributes(for: completedMessage, keepProperties: .isDuplicate)
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

    public func markAsSeen(messages: [Message], seen: Bool = true) async throws {
        if seen {
            _ = try await apiFetcher.markAsSeen(mailbox: mailbox, messages: messages)
        } else {
            _ = try await apiFetcher.markAsUnseen(mailbox: mailbox, messages: messages)
        }

        await backgroundRealm.execute { realm in
            for message in messages {
                if let liveMessage = message.fresh(using: realm) {
                    try? realm.safeWrite {
                        liveMessage.seen = seen
                        liveMessage.parent?.updateUnseenMessages()
                        liveMessage.parent?.parent?.incrementUnreadCount(by: seen ? -1 : 1)
                    }
                }
            }
        }
    }

    public func move(messages: [Message], to folder: Folder) async throws -> UndoRedoAction {
        let response = try await apiFetcher.move(mailbox: mailbox, messages: messages, destinationId: folder._id)

        let redoBlock = await backgroundRealm.execute { realm in
            if let folder = folder.fresh(using: realm) {
                let messages = messages.compactMap { $0.fresh(using: realm) }
                return try? self.moveLocally(messages: messages, to: folder, using: realm)
            } else {
                return nil
            }
        }

        return UndoRedoAction(undo: response, redo: redoBlock)
    }

    public func move(messages: [Message], to folderRole: FolderRole) async throws -> UndoRedoAction {
        guard let folder = getFolder(with: folderRole)?.freeze() else { throw MailError.folderNotFound }
        return try await move(messages: messages, to: folder)
    }

    public func delete(messages: [Message]) async throws {
        _ = try await apiFetcher.delete(mailbox: mailbox, messages: messages)

        await backgroundRealm.execute { realm in
            for message in messages {
                if let liveMessage = message.fresh(using: realm) {
                    let parent = liveMessage.parent
                    try? realm.safeWrite {
                        realm.delete(liveMessage)
                        if let parent = parent {
                            if parent.messages.isEmpty {
                                realm.delete(parent)
                            } else {
                                parent.messagesCount -= 1
                            }
                        }
                    }
                }
            }
        }
    }

    public func reportSpam(messages: [Message]) async throws -> UndoRedoAction {
        let response = try await apiFetcher.reportSpam(mailbox: mailbox, messages: messages)

        let redoBlock = await backgroundRealm.execute { realm in
            if let spamFolder = self.getFolder(with: .spam, using: realm) {
                return try? self.moveLocally(messages: messages, to: spamFolder, using: realm)
            } else {
                return nil
            }
        }

        return UndoRedoAction(undo: response, redo: redoBlock)
    }

    public func nonSpam(messages: [Message]) async throws -> UndoRedoAction {
        let response = try await apiFetcher.nonSpam(mailbox: mailbox, messages: messages)

        let redoBlock = await backgroundRealm.execute { realm in
            if let inboxFolder = self.getFolder(with: .inbox, using: realm) {
                return try? self.moveLocally(messages: messages, to: inboxFolder, using: realm)
            } else {
                return nil
            }
        }

        return UndoRedoAction(undo: response, redo: redoBlock)
    }

    public func star(messages: [Message]) async throws -> MessageActionResult {
        let response = try await apiFetcher.star(mailbox: mailbox, messages: messages)

        await backgroundRealm.execute { realm in
            try? realm.safeWrite {
                for message in messages {
                    if let liveMessage = message.fresh(using: realm) {
                        liveMessage.flagged = true
                        liveMessage.parent?.updateFlagged()
                    }
                }
            }
        }

        return response
    }

    public func unstar(messages: [Message]) async throws -> MessageActionResult {
        let response = try await apiFetcher.unstar(mailbox: mailbox, messages: messages)

        await backgroundRealm.execute { realm in
            try? realm.safeWrite {
                for message in messages {
                    if let liveMessage = message.fresh(using: realm) {
                        liveMessage.flagged = false
                        liveMessage.parent?.updateFlagged()
                    }
                }
            }
        }

        return response
    }

    private func moveLocally(messages: [Message], to folder: Folder, using realm: Realm) throws -> UndoRedoAction.RedoBlock {
        // Keep a dictionary of MessageId -> FolderId in case we want to restore them
        let previousFolders = messages.compactMap { realm.object(ofType: Folder.self, forPrimaryKey: $0.folderId)?.freeze() }

        try realm.safeWrite {
            for message in messages {
                if let liveMessage = message.fresh(using: realm) {
                    liveMessage.parent?.updateUnseenMessages()
                    liveMessage.parent?.parent?.incrementUnreadCount(by: -1)
                    liveMessage.folder = folder.name
                    liveMessage.folderId = folder._id
                }
            }
            let liveFolder = folder.fresh(using: realm)
            liveFolder?.unreadCount = (liveFolder?.unreadCount ?? 0) + messages.filter { !$0.seen }.count
            if messages.count == 1, let thread = messages.first?.fresh(using: realm)?.parent {
                thread.parent?.threads.remove(thread)
            }
        }

        return { [weak self] in
            // Try to do only one API call if possible
            // FIXME: This is only a temporary solution
            if previousFolders.allSatisfy({ $0._id == previousFolders.first?._id }),
               let previousFolder = previousFolders.first {
                _ = try await self?.threads(folder: previousFolder)
            } else {
                await withThrowingTaskGroup(of: Void.self) { group in
                    for previousFolder in previousFolders {
                        group.addTask { [weak self] in
                            _ = try await self?.threads(folder: previousFolder)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Draft

    public func draft(from message: Message) async throws -> Draft {
        // Get from API
        let draft = try await apiFetcher.draft(from: message)

        await backgroundRealm.execute { realm in
            // Get draft from Realm to keep local saved properties
            if let savedDraft = realm.object(ofType: Draft.self, forPrimaryKey: draft.uuid) {
                draft.isOffline = savedDraft.isOffline
                draft.messageUid = message.uid
            }

            // Update draft in Realm
            try? realm.safeWrite {
                realm.add(draft.detached(), update: .modified)
            }
        }

        return draft
    }

    public func draft(messageUid: String, using realm: Realm? = nil) -> Draft? {
        let realm = realm ?? getRealm()
        return realm.objects(Draft.self).where { $0.messageUid == messageUid }.first
    }

    public func draft(uuid: String, using realm: Realm? = nil) -> Draft? {
        let realm = realm ?? getRealm()
        return realm.objects(Draft.self).where { $0.uuid == uuid }.first
    }

    public func send(draft: UnmanagedDraft) async throws -> CancelResponse {
        // If the draft has no UUID, we save it first
        if draft.uuid.isEmpty {
            _ = await save(draft: draft)
        }
        var draft = draft
        draft.action = .send
        draft.delay = UserDefaults.shared.cancelSendDelay.rawValue
        let cancelableResponse = try await apiFetcher.send(mailbox: mailbox, draft: draft)
        // Once the draft has been sent, we can delete it from Realm
        await delete(draft: draft)
        return cancelableResponse
    }

    public func save(draft: UnmanagedDraft) async -> (uuid: String, error: Error?) {
        var draft = draft
        draft.action = .save
        do {
            let saveResponse = try await apiFetcher.save(mailbox: mailbox, draft: draft)

            let draft = draft.asManaged()
            let oldUuid = draft.uuid
            draft.uuid = saveResponse.uuid
            draft.messageUid = saveResponse.uid
            draft.isOffline = false

            let copyDraft = draft.detached()
            await backgroundRealm.execute { realm in
                // Update draft in Realm
                try? realm.safeWrite {
                    realm.add(copyDraft, update: .modified)
                }
                if let draft = realm.object(ofType: Draft.self, forPrimaryKey: oldUuid),
                   oldUuid.starts(with: Draft.uuidLocalPrefix) {
                    // Delete local draft in Realm
                    try? realm.safeWrite {
                        realm.delete(draft)
                    }
                }
            }
            return (draft.uuid, nil)
        } catch {
            let draft = draft.asManaged()
            if draft.uuid.isEmpty {
                draft.uuid = Draft.uuidLocalPrefix + UUID().uuidString
            }
            draft.isOffline = true
            draft.date = Date()
            let copyDraft = draft.detached()

            await backgroundRealm.execute { realm in
                // Update draft in Realm
                try? realm.safeWrite {
                    realm.add(copyDraft, update: .modified)
                }
            }
            return (draft.uuid, error)
        }
    }

    public func delete(draft: AbstractDraft) async {
        await backgroundRealm.execute { realm in
            if let draft = realm.object(ofType: Draft.self, forPrimaryKey: draft.uuid) {
                try? realm.safeWrite {
                    realm.delete(draft)
                }
            } else {
                print("No draft with uuid \(draft.uuid)")
            }
        }
    }

    public func deleteDraft(from message: Message) async throws {
        // Delete from API
        try await apiFetcher.deleteDraft(from: message)
        await backgroundRealm.execute { realm in
            if let draft = self.draft(messageUid: message.uid, using: realm) {
                // Delete draft in Realm
                try? realm.safeWrite {
                    realm.delete(draft)
                }
            }
        }
    }

    public func draftOffline() async {
        await backgroundRealm.execute { realm in
            let draftOffline = AnyRealmCollection(realm.objects(Draft.self).where { $0.isOffline == true })

            let offlineDraftThread = List<Thread>()

            guard let folder = self.getFolder(with: .draft, using: realm) else { return }

            let messagesList = realm.objects(Message.self).where { $0.folderId == folder.id }
            for draft in draftOffline where !messagesList.contains(where: { $0.uid == draft.messageUid }) {
                let thread = Thread(draft: draft)
                let from = Recipient(email: self.mailbox.email, name: self.mailbox.emailIdn)
                thread.from.append(from)
                offlineDraftThread.append(thread)
            }

            // Update message in Realm
            try? realm.safeWrite {
                realm.add(offlineDraftThread, update: .modified)
                folder.threads.insert(objectsIn: offlineDraftThread)
            }
        }
    }

    /// Delete local draft from its associated thread
    /// - Parameter thread: Thread associated to local draft
    public func deleteLocalDraft(thread: Thread) async {
        await backgroundRealm.execute { realm in
            if let message = thread.messages.first,
               let draft = self.draft(messageUid: message.uid) {
                try? realm.safeWrite {
                    realm.delete(draft)
                }
            }
            // Delete thread
            if let liveThread = thread.fresh(using: realm) {
                try? realm.safeWrite {
                    realm.delete(liveThread.messages)
                    realm.delete(liveThread)
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
        static let isDuplicate = MessagePropertiesOptions(rawValue: 1 << 3)

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
        if keepProperties.contains(.isDuplicate) {
            message.isDuplicate = savedMessage.isDuplicate
        }
    }

    private func keepCacheAttributes(
        for folder: Folder,
        using realm: Realm
    ) {
        guard let savedFolder = realm.object(ofType: Folder.self, forPrimaryKey: folder._id) else { return }
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
        return realm.objects(Folder.self).contains { $0.unreadCount != nil && $0.unreadCount! > 0 }
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
