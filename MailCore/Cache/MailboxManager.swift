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

    public var realmConfiguration: Realm.Configuration
    public var mailbox: Mailbox
    public private(set) var apiFetcher: MailApiFetcher

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

        let realm = getRealm()

        // Update signatures in Realm
        try? realm.safeWrite {
            realm.add(signaturesResult, update: .modified)
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

        let realm = getRealm()
        for folder in newFolders {
            keepCacheAttributes(for: folder, using: realm)
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
            for thread in mayBeDeletedThreads {
                if Set(thread.messages).isSubset(of: toDeleteMessages) {
                    toDeleteThreads.append(thread)
                }
            }

            realm.delete(toDeleteMessages)
            realm.delete(toDeleteThreads)
            realm.delete(toDeleteFolders)
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
        let folder = try await apiFetcher.create(mailbox: mailbox, folder: NewFolder(name: name, path: parent?.path))
        let realm = getRealm()
        try? realm.write {
            realm.add(folder)
            parent?.thaw()?.children.insert(folder)
        }
        return folder.freeze()
    }

    // MARK: - Thread

    public func threads(folder: Folder, filter: Filter = .all, searchFilter: [URLQueryItem] = []) async throws -> ThreadResult {
        // Get from API
        let threadResult = try await apiFetcher.threads(
            mailbox: mailbox,
            folderId: folder._id,
            filter: filter,
            searchFilter: searchFilter
        )

        // Save result
        saveThreads(result: threadResult, parent: folder)

        return threadResult
    }

    public func threads(folder: Folder, resource: String) async throws -> ThreadResult {
        // Get from API
        let threadResult = try await apiFetcher.threads(from: resource)

        // Save result
        saveThreads(result: threadResult, parent: folder)

        return threadResult
    }

    private func saveThreads(result: ThreadResult, parent: Folder) {
        guard let parentFolder = parent.thaw() else { return }
        let realm = getRealm()

        let fetchedThreads = MutableSet<Thread>()
        fetchedThreads.insert(objectsIn: result.threads ?? [])

        for thread in fetchedThreads {
            for message in thread.messages {
                keepCacheAttributes(for: message, keepProperties: .standard, using: realm)
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

    public func toggleRead(threads: [Thread]) async throws {
        if threads.contains(where: { $0.unseenMessages > 0 }) {
            _ = try await apiFetcher.markAsSeen(mailbox: mailbox, messages: threads.flatMap(\.messages))
            let realm = getRealm()
            for thread in threads {
                markAsSeen(thread: thread, using: realm)
            }
        } else {
            _ = try await apiFetcher.markAsUnseen(mailbox: mailbox, messages: threads.flatMap(\.messages))
            let realm = getRealm()
            for thread in threads {
                markAsUnseen(thread: thread, using: realm)
            }
        }
    }

    public func toggleRead(thread: Thread) async throws {
        if thread.unseenMessages > 0 {
            _ = try await apiFetcher.markAsSeen(mailbox: mailbox, messages: Array(thread.messages))
            markAsSeen(thread: thread)
        } else {
            _ = try await apiFetcher.markAsUnseen(mailbox: mailbox, messages: Array(thread.messages))
            markAsUnseen(thread: thread)
        }
    }

    public func move(threads: [Thread], to folder: Folder) async throws -> UndoResponse {
        let response = try await apiFetcher.move(mailbox: mailbox, messages: threads.flatMap(\.messages), destinationId: folder._id)

        if let liveFolder = folder.thaw() {
            let realm = getRealm()
            for thread in threads {
                if let liveThread = thread.thaw() {
                    try? moveLocally(thread: liveThread, to: liveFolder, using: realm)
                }
            }
        }
        return response
    }

    public func move(thread: Thread, to folder: Folder) async throws -> UndoResponse {
        let response = try await apiFetcher.move(mailbox: mailbox, messages: Array(thread.messages), destinationId: folder._id)

        if let liveFolder = folder.thaw(), let liveThread = thread.thaw() {
            try? moveLocally(thread: liveThread, to: liveFolder)
        }

        return response
    }

    public func move(threads: [Thread], to folderRole: FolderRole) async throws -> UndoResponse {
        guard let folder = getFolder(with: folderRole)?.freeze() else { throw MailError.folderNotFound }
        return try await move(threads: threads, to: folder)
    }

    public func move(thread: Thread, to folderRole: FolderRole) async throws -> UndoResponse {
        guard let folder = getFolder(with: folderRole)?.freeze() else { throw MailError.folderNotFound }
        return try await move(thread: thread, to: folder)
    }

    public func delete(threads: [Thread]) async throws {
        _ = try await apiFetcher.delete(mailbox: mailbox, messages: threads.flatMap(\.messages))

        let realm = getRealm()
        for thread in threads {
            if let liveThread = thread.thaw() {
                try? realm.safeWrite {
                    liveThread.parent?.unreadCount = (liveThread.parent?.unreadCount ?? 0) - liveThread.unseenMessages
                    realm.delete(liveThread.messages)
                    realm.delete(liveThread)
                }
            }
        }
    }

    public func delete(thread: Thread) async throws {
        _ = try await apiFetcher.delete(mailbox: mailbox, messages: Array(thread.messages))

        let realm = getRealm()
        if let liveThread = thread.thaw() {
            try? realm.safeWrite {
                liveThread.parent?.unreadCount = (liveThread.parent?.unreadCount ?? 0) - liveThread.unseenMessages
                realm.delete(liveThread.messages)
                realm.delete(liveThread)
            }
        }
    }

    public func moveOrDelete(threads: [Thread]) async throws {
        let realm = getRealm()
        let draftThreads = threads.filter { $0.parent?.role == .draft && $0.uid.starts(with: Draft.uuidLocalPrefix) }
        for draft in draftThreads {
            deleteLocalDraft(thread: draft, using: realm)
        }

        let otherThreads = threads.filter { !($0.parent?.role == .draft && $0.uid.starts(with: Draft.uuidLocalPrefix)) }
        let parentFolder = otherThreads.first?.parent
        if parentFolder?.role == .trash {
            try await delete(threads: otherThreads)
        } else {
            let response = try await move(threads: threads, to: .trash)
            let folderName = FolderRole.trash.localizedName
            Task.detached {
                await IKSnackBar.showCancelableSnackBar(message: MailResourcesStrings.Localizable.snackbarThreadMoved(folderName),
                                                        cancelSuccessMessage: MailResourcesStrings.Localizable.snackbarMoveCancelled,
                                                        cancelableResponse: response,
                                                        mailboxManager: self)
            }
        }
    }

    /// Move to trash or delete thread, depending on its current state
    /// - Parameter thread: Thread to remove
    public func moveOrDelete(thread: Thread) async throws {
        let parentFolder = thread.parent
        if parentFolder?.toolType == nil {
            deleteInSearch(thread: thread)
        }
        if parentFolder?.role == .trash {
            // Delete definitely
            try await delete(thread: thread)
        } else if parentFolder?.role == .draft && thread.uid.starts(with: Draft.uuidLocalPrefix) {
            // Delete local draft from Realm
            deleteLocalDraft(thread: thread)
        } else {
            // Move to trash
            let response = try await move(thread: thread, to: .trash)
            let folderName = FolderRole.trash.localizedName
            Task.detached {
                await IKSnackBar.showCancelableSnackBar(message: MailResourcesStrings.Localizable.snackbarThreadMoved(folderName),
                                                        cancelSuccessMessage: MailResourcesStrings.Localizable
                                                            .snackbarMoveCancelled,
                                                        cancelableResponse: response,
                                                        mailboxManager: self)
            }
        }
    }

    private func deleteInSearch(thread: Thread, using realm: Realm? = nil) {
        let realm = realm ?? getRealm()
        guard let searchFolder = realm.object(ofType: Folder.self, forPrimaryKey: Constants.searchFolderId),
              let thread = thread.thaw() else { return }

        try? realm.safeWrite {
            searchFolder.threads.remove(thread)
        }
    }

    public func reportSpam(threads: [Thread]) async throws -> UndoResponse {
        let response = try await apiFetcher.reportSpam(mailbox: mailbox, messages: threads.flatMap(\.messages))

        let realm = getRealm()
        if let spamFolder = getFolder(with: .spam, using: realm) {
            for thread in threads {
                if let liveThread = thread.thaw() {
                    try? moveLocally(thread: liveThread, to: spamFolder)
                }
            }
        }

        return response
    }

    public func reportSpam(thread: Thread) async throws -> UndoResponse {
        let response = try await apiFetcher.reportSpam(mailbox: mailbox, messages: Array(thread.messages))

        let realm = getRealm()
        if let spamFolder = getFolder(with: .spam, using: realm), let liveThread = thread.thaw() {
            try? moveLocally(thread: liveThread, to: spamFolder)
        }

        return response
    }

    public func nonSpam(threads: [Thread]) async throws -> UndoResponse {
        let response = try await apiFetcher.nonSpam(mailbox: mailbox, messages: threads.flatMap(\.messages))

        let realm = getRealm()
        if let inboxFolder = getFolder(with: .inbox, using: realm) {
            for thread in threads {
                if let liveThread = thread.thaw() {
                    try? moveLocally(thread: liveThread, to: inboxFolder)
                }
            }
        }

        return response
    }

    public func nonSpam(thread: Thread) async throws -> UndoResponse {
        let response = try await apiFetcher.nonSpam(mailbox: mailbox, messages: Array(thread.messages))

        let realm = getRealm()
        if let inboxFolder = getFolder(with: .inbox, using: realm), let liveThread = thread.thaw() {
            try? moveLocally(thread: liveThread, to: inboxFolder)
        }

        return response
    }

    public func toggleStar(threads: [Thread]) async throws {
        if threads.contains(where: { !$0.flagged }) {
            _ = try await apiFetcher.star(mailbox: mailbox, messages: threads.flatMap(\.messages))
            let realm = getRealm()
            for thread in threads {
                star(thread: thread, using: realm)
            }
        } else {
            _ = try await apiFetcher.unstar(mailbox: mailbox, messages: threads.flatMap(\.messages))
            let realm = getRealm()
            for thread in threads {
                unstar(thread: thread, using: realm)
            }
        }
    }

    public func toggleStar(thread: Thread) async throws {
        if thread.flagged {
            _ = try await apiFetcher.unstar(mailbox: mailbox, messages: Array(thread.messages))
            unstar(thread: thread)
        } else {
            guard let lastMessage = thread.messages.last else { return }
            _ = try await apiFetcher.star(mailbox: mailbox, messages: [lastMessage])
            star(thread: thread)
        }
    }

    private func moveLocally(thread: Thread, to folder: Folder, using realm: Realm? = nil) throws {
        let realm = realm ?? getRealm()
        try realm.safeWrite {
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

    private func markAsSeen(thread: Thread, using realm: Realm? = nil) {
        if let liveThread = thread.thaw() {
            let realm = realm ?? getRealm()
            try? realm.safeWrite {
                liveThread.parent?.unreadCount = (liveThread.parent?.unreadCount ?? 0) - liveThread.unseenMessages
                liveThread.unseenMessages = 0
                for message in thread.messages {
                    message.thaw()?.seen = true
                }
            }
        }
    }

    private func markAsUnseen(thread: Thread, using realm: Realm? = nil) {
        if let liveThread = thread.thaw() {
            let realm = realm ?? getRealm()
            try? realm.safeWrite {
                liveThread.unseenMessages = liveThread.messagesCount
                liveThread.parent?.unreadCount = (liveThread.parent?.unreadCount ?? 0) + liveThread.unseenMessages
                for message in thread.messages {
                    message.thaw()?.seen = false
                }
            }
        }
    }

    private func star(thread: Thread, using realm: Realm? = nil) {
        guard let lastMessage = thread.messages.last else { return }
        if let liveThread = thread.thaw() {
            let realm = realm ?? getRealm()
            try? realm.safeWrite {
                liveThread.flagged = true
                lastMessage.thaw()?.flagged = true
            }
        }
    }

    private func unstar(thread: Thread, using realm: Realm? = nil) {
        if let liveThread = thread.thaw() {
            let realm = realm ?? getRealm()
            try? realm.safeWrite {
                liveThread.flagged = false
                for message in thread.messages {
                    message.thaw()?.flagged = false
                }
            }
        }
    }

    // MARK: - Search

    public func initSearchFolder() -> Folder {
        let realm = getRealm()

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

        try? realm.safeWrite {
            realm.add(searchFolder, update: .modified)
        }

        return searchFolder
    }

    public func cleanSearchFolder(using realm: Realm? = nil) -> Folder {
        let realm = realm ?? getRealm()
        if let folder = realm.object(ofType: Folder.self, forPrimaryKey: Constants.searchFolderId) {
            try? realm.safeWrite {
                realm.delete(folder.threads.where { $0.fromSearch == true })
                folder.threads.removeAll()
            }
            return folder
        } else {
            return initSearchFolder()
        }
    }

    public func searchThreads(@ThreadSafe searchFolder: Folder?, filterFolderId: String, filter: Filter = .all,
                              searchFilter: [URLQueryItem] = []) async throws -> ThreadResult {
        let threadResult = try await apiFetcher.threads(
            mailbox: mailbox,
            folderId: filterFolderId,
            filter: filter,
            searchFilter: searchFilter
        )

        let realm = getRealm()
        for thread in threadResult.threads ?? [] {
            if realm.object(ofType: Thread.self, forPrimaryKey: thread.uid) == nil {
                thread.fromSearch = true
            }
        }

        if let searchFolder = searchFolder {
            saveThreads(result: threadResult, parent: searchFolder)
        }

        return threadResult
    }

    public func searchThreads(@ThreadSafe searchFolder: Folder?, from resource: String,
                              searchFilter: [URLQueryItem] = []) async throws -> ThreadResult {
        let threadResult = try await apiFetcher.threads(from: resource, searchFilter: searchFilter)

        let realm = getRealm()
        for thread in threadResult.threads ?? [] {
            if realm.object(ofType: Thread.self, forPrimaryKey: thread.uid) == nil {
                thread.fromSearch = true
            }
        }

        if let searchFolder = searchFolder {
            saveThreads(result: threadResult, parent: searchFolder)
        }

        return threadResult
    }

    public func searchHistory(using realm: Realm? = nil) -> SearchHistory {
        let realm = realm ?? getRealm()
        if let searchHistory = realm.objects(SearchHistory.self).first {
            return searchHistory.freeze()
        }
        let newSearchHistory = SearchHistory()
        try? realm.safeWrite {
            realm.add(newSearchHistory)
        }
        return newSearchHistory
    }

    public func update(searchHistory: SearchHistory, with value: String) -> SearchHistory {
        let realm = getRealm()
        realm.refresh()
        guard let searchHistory = searchHistory.thaw() else { return searchHistory }

        try? realm.safeWrite {
            if let indexToRemove = searchHistory.history.firstIndex(of: value) {
                searchHistory.history.remove(at: indexToRemove)
            }
            searchHistory.history.insert(value, at: 0)
        }

        return searchHistory.freeze()
    }

    public func clearSearchHistory() {
        let realm = getRealm()
        let searchHistory = searchHistory(using: realm)
        try? realm.safeWrite {
            searchHistory.history.removeAll()
        }
    }

    // MARK: - Message

    public func message(message: Message) async throws {
        // Get from API
        let completedMessage = try await apiFetcher.message(message: message)
        completedMessage.insertInlineAttachment()
        keepCacheAttributes(for: completedMessage, keepProperties: .isDuplicate)
        completedMessage.fullyDownloaded = true

        let realm = getRealm()

        // Update message in Realm
        try? realm.safeWrite {
            realm.add(completedMessage, update: .modified)
        }
    }

    public func attachmentData(attachment: Attachment) async throws -> Data {
        let data = try await apiFetcher.attachment(attachment: attachment)

        if let liveAttachment = attachment.thaw() {
            let realm = getRealm()
            try? realm.safeWrite {
                liveAttachment.saved = true
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

        let realm = getRealm()
        for message in messages {
            if let liveMessage = message.thaw() {
                try? realm.safeWrite {
                    liveMessage.seen = seen
                    liveMessage.parent?.updateUnseenMessages()
                    liveMessage.parent?.parent?.incrementUnreadCount(by: seen ? -1 : 1)
                }
            }
        }
    }

    public func move(messages: [Message], to folder: Folder) async throws -> UndoResponse {
        let response = try await apiFetcher.move(mailbox: mailbox, messages: messages, destinationId: folder._id)

        try? moveLocally(messages: messages, to: folder)

        return response
    }

    public func move(messages: [Message], to folderRole: FolderRole) async throws -> UndoResponse {
        guard let folder = getFolder(with: folderRole)?.freeze() else { throw MailError.folderNotFound }
        return try await move(messages: messages, to: folder)
    }

    public func delete(messages: [Message]) async throws {
        _ = try await apiFetcher.delete(mailbox: mailbox, messages: messages)

        let realm = getRealm()
        for message in messages {
            if let liveMessage = message.thaw() {
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

    public func reportSpam(messages: [Message]) async throws -> UndoResponse {
        let response = try await apiFetcher.reportSpam(mailbox: mailbox, messages: messages)

        let realm = getRealm()
        guard let spamFolder = getFolder(with: .spam, using: realm)?.freeze() else { return response }
        try? moveLocally(messages: messages, to: spamFolder, using: realm)

        return response
    }

    public func nonSpam(messages: [Message]) async throws -> UndoResponse {
        let response = try await apiFetcher.nonSpam(mailbox: mailbox, messages: messages)

        let realm = getRealm()
        guard let inboxFolder = getFolder(with: .inbox, using: realm)?.freeze() else { return response }
        try? moveLocally(messages: messages, to: inboxFolder, using: realm)

        return response
    }

    public func star(messages: [Message]) async throws -> MessageActionResult {
        let response = try await apiFetcher.star(mailbox: mailbox, messages: messages)

        let realm = getRealm()
        for message in messages {
            if let liveMessage = message.thaw() {
                try? realm.safeWrite {
                    liveMessage.flagged = true
                    liveMessage.parent?.updateFlagged()
                }
            }
        }

        return response
    }

    public func unstar(messages: [Message]) async throws -> MessageActionResult {
        let response = try await apiFetcher.unstar(mailbox: mailbox, messages: messages)

        let realm = getRealm()
        for message in messages {
            if let liveMessage = message.thaw() {
                try realm.safeWrite {
                    liveMessage.flagged = false
                    liveMessage.parent?.updateFlagged()
                }
            }
        }

        return response
    }

    private func moveLocally(messages: [Message], to folder: Folder, using realm: Realm? = nil) throws {
        let realm = realm ?? getRealm()
        try realm.safeWrite {
            for message in messages {
                if let liveMessage = message.thaw() {
                    liveMessage.parent?.updateUnseenMessages()
                    liveMessage.parent?.parent?.incrementUnreadCount(by: -1)
                    liveMessage.folder = folder.name
                    liveMessage.folderId = folder._id
                }
            }
            let liveFolder = folder.thaw()
            liveFolder?.unreadCount = (liveFolder?.unreadCount ?? 0) + messages.filter { !$0.seen }.count
            if messages.count == 1, let thread = messages.first?.parent?.thaw() {
                thread.parent?.threads.remove(thread)
            }
        }
    }

    // MARK: - Draft

    public func draft(from message: Message) async throws -> Draft {
        // Get from API
        let draft = try await apiFetcher.draft(from: message)

        let realm = getRealm()

        // Update draft in Realm
        try? realm.safeWrite {
            realm.add(draft.detached(), update: .modified)
        }

        return draft
    }

    public func draft(messageUid: String, using realm: Realm? = nil) -> Draft? {
        let realm = realm ?? getRealm()
        return realm.objects(Draft.self).where { $0.messageUid == messageUid }.first
    }

    public func send(draft: UnmanagedDraft) async throws -> CancelResponse {
        // If the draft has no UUID, we save it first
        if draft.uuid.isEmpty {
            _ = try await save(draft: draft)
        }
        var draft = draft
        draft.action = .send
        draft.delay = UserDefaults.shared.cancelSendDelay.rawValue
        let cancelableResponse = try await apiFetcher.send(mailbox: mailbox, draft: draft)
        // Once the draft has been sent, we can delete it from Realm
        delete(draft: draft)
        return cancelableResponse
    }

    public func save(draft: UnmanagedDraft) async throws -> DraftResponse {
        var draft = draft
        draft.action = .save
        do {
            let saveResponse = try await apiFetcher.save(mailbox: mailbox, draft: draft)

            let realm = getRealm()
            let draft = draft.asManaged()
            let oldUuid = draft.uuid
            draft.uuid = saveResponse.uuid
            draft.messageUid = saveResponse.uid
            draft.isOffline = false

            let copyDraft = draft.detached()

            // Update draft in Realm
            try? realm.safeWrite {
                realm.add(copyDraft, update: .modified)
            }
            if let draft = realm.object(ofType: Draft.self, forPrimaryKey: oldUuid), oldUuid.starts(with: Draft.uuidLocalPrefix) {
                // Delete local draft in Realm
                try? realm.safeWrite {
                    realm.delete(draft)
                }
            }
            return saveResponse
        } catch {
            let realm = getRealm()
            let draft = draft.asManaged()
            if draft.uuid.isEmpty {
                draft.uuid = Draft.uuidLocalPrefix + UUID().uuidString
            }
            draft.isOffline = true
            draft.date = Date()
            let copyDraft = draft.detached()

            // Update draft in Realm
            try? realm.safeWrite {
                realm.add(copyDraft, update: .modified)
            }
            throw error
        }
    }

    public func delete(draft: AbstractDraft) {
        let realm = getRealm()
        if let draft = realm.object(ofType: Draft.self, forPrimaryKey: draft.uuid) {
            try? realm.safeWrite {
                realm.delete(draft)
            }
        } else {
            print("No draft with uuid \(draft.uuid)")
        }
    }

    public func deleteDraft(from message: Message) async throws {
        // Delete from API
        try await apiFetcher.deleteDraft(from: message)
        if let draft = draft(messageUid: message.uid) {
            let realm = getRealm()

            // Delete draft in Realm
            try? realm.safeWrite {
                realm.delete(draft)
            }
        }
    }

    public func draftOffline() {
        let realm = getRealm()
        let draftOffline = AnyRealmCollection(realm.objects(Draft.self).where { $0.isOffline == true })

        let offlineDraftThread = List<Thread>()

        guard let folder = getFolder(with: .draft, using: realm) else { return }

        for draft in draftOffline {
            let thread = Thread(draft: draft)
            let from = Recipient(email: mailbox.email, name: mailbox.emailIdn)
            thread.from.append(from)
            offlineDraftThread.append(thread)
        }

        // Update message in Realm
        try? realm.safeWrite {
            realm.add(offlineDraftThread, update: .modified)
            folder.threads.insert(objectsIn: offlineDraftThread)
        }
    }

    /// Delete local draft from its associated thread
    /// - Parameter thread: Thread associated to local draft
    public func deleteLocalDraft(thread: Thread, using realm: Realm? = nil) {
        let realm = realm ?? getRealm()
        if let message = thread.messages.first, let draft = draft(messageUid: message.uid) {
            try? realm.safeWrite {
                realm.delete(draft)
            }
        }
        // Delete thread
        if let liveThread = thread.thaw() {
            try? realm.safeWrite {
                realm.delete(liveThread.messages)
                realm.delete(liveThread)
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
        using realm: Realm? = nil
    ) {
        let realm = realm ?? getRealm()
        guard let savedFolder = realm.object(ofType: Folder.self, forPrimaryKey: folder._id) else { return }
        folder.lastUpdate = savedFolder.lastUpdate
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
    func safeWrite(_ block: () throws -> Void) throws {
        if isInWriteTransaction {
            try block()
        } else {
            try write(block)
        }
    }
}
