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

public class MailboxManager: ObservableObject {
    public class MailboxManagerConstants {
        private let fileManager = FileManager.default
        public let rootDocumentsURL: URL
        public let groupDirectoryURL: URL
        public let cacheDirectoryURL: URL
        // TRY THIS
//        public let temporaryDirectoryURL: URL

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

    // MARK: - Thread

    public func threads(folder: Folder, filter: Filter = .all) async throws {
        // Get from Realm
        guard ReachabilityListener.instance.currentStatus != .offline else {
            return
        }
        // Get from API
        let threadResult = try await apiFetcher.threads(mailbox: mailbox, folder: folder, filter: filter)

        let realm = getRealm()

        guard let parentFolder = realm.object(ofType: Folder.self, forPrimaryKey: folder.id) else { return }

        let fetchedThreads = MutableSet<Thread>()
        fetchedThreads.insert(objectsIn: threadResult.threads ?? [])

        for thread in fetchedThreads {
            for message in thread.messages {
                keepCacheAttributes(for: message, keepProperties: .standard, using: realm)
            }
        }

        // Update thread in Realm
        try? realm.safeWrite {
            realm.add(fetchedThreads, update: .modified)
            let toDeleteThreads = Set(parentFolder.threads).subtracting(Set(fetchedThreads))
            let toDeleteMessages = Set(toDeleteThreads.flatMap(\.messages))
            parentFolder.threads = fetchedThreads

            realm.delete(toDeleteMessages)
            realm.delete(toDeleteThreads)
        }
    }

    // MARK: - Message

    public func message(message: Message) async throws {
        // Get from API
        let completedMessage = try await apiFetcher.message(mailbox: mailbox, message: message)
        message.insertInlineAttachment()
        completedMessage.fullyDownloaded = true

        let realm = getRealm()

        // Update message in Realm
        try? realm.safeWrite {
            realm.add(completedMessage, update: .modified)
        }
    }

    public func attachmentData(attachment: Attachment) async throws -> Attachment {
        let data = try await apiFetcher.attachment(mailbox: mailbox, attachment: attachment)

        if let liveAttachment = attachment.thaw() {
            let realm = getRealm()
            try? realm.safeWrite {
                liveAttachment.data = data
            }
            return liveAttachment
        } else {
            return attachment
        }
    }

    public func saveAttachmentLocally(attachment: Attachment) async {
        do {
            let liveAttachment = try await attachmentData(attachment: attachment)
            if let data = liveAttachment.data, let url = liveAttachment.localUrl {
                try data.write(to: url)
            }
        } catch {
            // Handle error
        }
    // MARK: - Draft

    public func draft(draftUuid: String) async throws -> Draft {
        // Get from API
        let draft = try await apiFetcher.draft(mailbox: mailbox, draftUuid: draftUuid)

        let realm = getRealm()

        // Update draft in Realm
        try? realm.safeWrite {
            realm.add(draft, update: .modified)
        }

        return draft
    }

    public func send(draft: Draft) async throws {
        _ = try await apiFetcher.send(mailbox: mailbox, draft: draft)
    }

    public func save(draft: Draft) async throws -> DraftResponse {
        let saveResponse = try await apiFetcher.save(mailbox: mailbox, draft: draft)
        return saveResponse
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
