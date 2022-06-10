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
                ValidEmail.self
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

    // MARK: - Thread

    public func threads(folder: Folder, filter: Filter = .all) async throws -> ThreadResult {
        // Get from API
        let threadResult = try await apiFetcher.threads(mailbox: mailbox, folder: folder, filter: filter)

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
            realm.add(fetchedThreads, update: .modified)
            // Clean old threads after fetching first page
            if result.currentOffset == 0 {
                let toDeleteThreads = Set(parentFolder.threads).subtracting(Set(fetchedThreads))
                let toDeleteMessages = Set(toDeleteThreads.flatMap(\.messages))
                parentFolder.threads = fetchedThreads

                realm.delete(toDeleteMessages)
                realm.delete(toDeleteThreads)
            } else {
                parentFolder.threads.insert(objectsIn: fetchedThreads)
            }
        }
    }

    // MARK: - Message

    public func message(message: Message) async throws {
        // Get from API
        let completedMessage = try await apiFetcher.message(mailbox: mailbox, message: message)
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
                try data.write(to: url)
            }
        } catch {
            // Handle error
        }
    }

    public func markAsSeen(message: Message, seen: Bool = true) async throws {
        if seen {
            _ = try await apiFetcher.markAsSeen(mailbox: mailbox, messages: [message])
        } else {
            _ = try await apiFetcher.markAsUnseen(mailbox: mailbox, messages: [message])
        }

        if let liveMessage = message.thaw() {
            let realm = getRealm()
            try? realm.safeWrite {
                liveMessage.seen = seen
                liveMessage.parent?.updateUnseenMessages()
            }
        }
    }

    public func toggleRead(thread: Thread) async throws {
        // Mark as seen
        if thread.unseenMessages > 0 {
            _ = try await apiFetcher.markAsSeen(mailbox: mailbox, messages: Array(thread.messages))
            if let liveThread = thread.thaw() {
                let realm = getRealm()
                try? realm.safeWrite {
                    liveThread.unseenMessages = 0
                    for message in thread.messages {
                        message.thaw()?.seen = true
                    }
                }
            }
        } else {
            // Mark as unseen
            _ = try await apiFetcher.markAsUnseen(mailbox: mailbox, messages: Array(thread.messages))
            if let liveThread = thread.thaw() {
                let realm = getRealm()
                try? realm.safeWrite {
                    liveThread.unseenMessages = liveThread.messagesCount
                    for message in thread.messages {
                        message.thaw()?.seen = false
                    }
                }
            }
        }
    }

    public func move(thread: Thread, to folder: Folder) async throws {
        _ = try await apiFetcher.move(mailbox: mailbox, messages: Array(thread.messages), destinationId: folder._id)

        let realm = getRealm()
        if let liveFolder = folder.thaw(), let liveThread = thread.thaw() {
            try? realm.safeWrite {
                liveThread.parent?.threads.remove(liveThread)
                liveFolder.threads.insert(liveThread)
                for message in liveThread.messages {
                    message.folder = folder.name
                    message.folderId = folder._id
                }
            }
        }
    }

    public func delete(thread: Thread) async throws {
        _ = try await apiFetcher.delete(mailbox: mailbox, messages: Array(thread.messages))

        let realm = getRealm()
        if let liveThread = thread.thaw() {
            try? realm.safeWrite {
                realm.delete(liveThread.messages)
                realm.delete(liveThread)
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

    public func draft(messageUid: String) -> Draft? {
        return getRealm().objects(Draft.self).where { $0.messageUid == messageUid }.first
    }

    public func send(draft: Draft) async throws -> Bool {
        // If the draft has no UUID, we save it first
        if draft.uuid.isEmpty {
            _ = try await save(draft: draft)
        }
        draft.action = .send
        let sendResponse = try await apiFetcher.send(mailbox: mailbox, draft: draft)
        if sendResponse {
            // Once the draft has been sent, we can delete it from Realm
            delete(draft: draft)
        }

        return sendResponse
    }

    public func save(draft: Draft) async throws -> DraftResponse {
        draft.action = .save
        do {
            let saveResponse = try await apiFetcher.save(mailbox: mailbox, draft: draft)

            let realm = getRealm()
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
            if draft.uuid.isEmpty {
                draft.uuid = Draft.uuidLocalPrefix + UUID().uuidString
            }
            draft.date = Date()
            let copyDraft = draft.detached()

            // Update draft in Realm
            try? realm.safeWrite {
                realm.add(copyDraft, update: .modified)
            }
            throw error
        }
    }

    public func delete(draft: Draft) {
        let realm = getRealm()
        if let draft = realm.object(ofType: Draft.self, forPrimaryKey: draft.uuid) {
            try? realm.safeWrite {
                realm.delete(draft)
            }
        } else {
            print("No draft with uuid \(draft.uuid)")
        }
    }

    public func deleteDraft(from message: Message) async throws -> Bool {
        // Delete from API
        let deleteResponse = try await apiFetcher.deleteDraft(from: message)
        // TODO: check if deletion was successful - if yes delete draft in realm if no display message
        if let draft = draft(messageUid: message.uid) {
            let realm = getRealm()

            // Delete draft in Realm
            try? realm.safeWrite {
                realm.delete(draft)
            }
        }
        return (deleteResponse != nil)
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
    public func deleteLocalDraft(thread: Thread) {
        let realm = getRealm()
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
    
    public func undoAction(resource: String) async throws {
        try await apiFetcher.undoAction(resource: resource)
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
