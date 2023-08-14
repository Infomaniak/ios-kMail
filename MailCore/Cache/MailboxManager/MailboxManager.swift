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
import InfomaniakDI
import RealmSwift
import SwiftRegex

public final class MailboxManager: ObservableObject, MailboxManageable {
    @LazyInjectService internal var snackbarPresenter: SnackBarPresentable

    internal lazy var refreshActor = RefreshActor(mailboxManager: self)
    internal let backgroundRealm: BackgroundRealm

    public static let constants = MailboxManagerConstants()

    public let realmConfiguration: Realm.Configuration
    public let mailbox: Mailbox
    public let account: Account

    public let apiFetcher: MailApiFetcher
    public let contactManager: ContactManager

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

    public init(account: Account, mailbox: Mailbox, apiFetcher: MailApiFetcher, contactManager: ContactManager) {
        self.account = account
        self.mailbox = mailbox
        self.apiFetcher = apiFetcher
        self.contactManager = contactManager
        let realmName = "\(mailbox.userId)-\(mailbox.mailboxId).realm"
        realmConfiguration = Realm.Configuration(
            fileURL: MailboxManager.constants.rootDocumentsURL.appendingPathComponent(realmName),
            schemaVersion: 18,
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

    // MARK: - Utilities

    struct MessagePropertiesOptions: OptionSet {
        let rawValue: Int

        static let fullyDownloaded = MessagePropertiesOptions(rawValue: 1 << 0)
        static let body = MessagePropertiesOptions(rawValue: 1 << 1)
        static let attachments = MessagePropertiesOptions(rawValue: 1 << 2)
        static let localSafeDisplay = MessagePropertiesOptions(rawValue: 1 << 3)

        static let standard: MessagePropertiesOptions = [.fullyDownloaded, .body, .attachments, .localSafeDisplay]
    }

    internal func keepCacheAttributes(
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

    internal func keepCacheAttributes(
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

    internal func getSubFolders(from folders: [Folder], oldResult: [Folder] = []) -> [Folder] {
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

    public func cleanRealm() {
        Task {
            await backgroundRealm.execute { realm in

                let folders = realm.objects(Folder.self)
                let threads = realm.objects(Thread.self)
                let messages = realm.objects(Message.self)

                try? realm.safeWrite {
                    realm.delete(threads)
                    realm.delete(messages)
                    for folder in folders {
                        folder.cursor = nil
                        folder.resetHistoryInfo()
                        folder.computeUnreadCount()
                    }
                }
            }
        }
    }
}

// MARK: - Equatable conformance

extension MailboxManager: Equatable {
    public static func == (lhs: MailboxManager, rhs: MailboxManager) -> Bool {
        return lhs.mailbox.id == rhs.mailbox.id
    }
}
