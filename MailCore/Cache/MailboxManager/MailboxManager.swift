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
import InfomaniakDI
import RealmSwift
import SwiftRegex

public final class MailboxManager: ObservableObject, MailboxManageable {
    @LazyInjectService var mailboxInfosManager: MailboxInfosManager

    lazy var refreshActor = RefreshActor(mailboxManager: self)

    public static let constants = MailboxManagerConstants()

    public let realmConfiguration: Realm.Configuration
    public let transactionExecutor: Transactionable

    public let mailbox: Mailbox
    public let account: Account

    public let apiFetcher: MailApiFetcher
    public let contactManager: ContactManageable

    enum ErrorDomain: Error {
        case missingMessage
        case missingFolder
        case missingDraft
    }

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

    public init(account: Account, mailbox: Mailbox, apiFetcher: MailApiFetcher, contactManager: ContactManageable) {
        self.account = account
        self.mailbox = mailbox
        self.apiFetcher = apiFetcher
        self.contactManager = contactManager
        let realmName = "\(mailbox.userId)-\(mailbox.mailboxId).realm"
        realmConfiguration = Realm.Configuration(
            fileURL: MailboxManager.constants.rootDocumentsURL.appendingPathComponent(realmName),
            schemaVersion: 31,
            migrationBlock: { migration, oldSchemaVersion in
                // No migration needed from 0 to 16
                if oldSchemaVersion < 17 {
                    // Remove signatures without `senderName` and `senderEmailIdn`
                    migration.deleteData(forType: Signature.className())
                }
                if oldSchemaVersion < 20 {
                    migration.deleteData(forType: SearchHistory.className())
                }

                if oldSchemaVersion < 21 {
                    migration.enumerateObjects(ofType: Folder.className()) { oldObject, newObject in
                        newObject?["remoteId"] = oldObject?["_id"]
                    }
                }
                if oldSchemaVersion < 23 {
                    migration.deleteData(forType: Thread.className())
                    migration.deleteData(forType: Message.className())
                }
            },
            objectTypes: [
                Folder.self,
                Thread.self,
                Message.self,
                Body.self,
                SubBody.self,
                Attachment.self,
                Recipient.self,
                Draft.self,
                Signature.self,
                SearchHistory.self,
                CalendarEventResponse.self,
                CalendarEvent.self,
                Attendee.self,
                SwissTransferAttachment.self,
                File.self
            ]
        )

        let realmAccessor = MailCoreRealmAccessor(realmConfiguration: realmConfiguration)
        transactionExecutor = TransactionExecutor(realmAccessible: realmAccessor)

        excludeRealmFromBackup()
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

    func keepCacheAttributes(
        for message: Message,
        keepProperties: MessagePropertiesOptions,
        using realm: Realm
    ) {
        guard let savedMessage = realm.object(ofType: Message.self, forPrimaryKey: message.uid) else {
            logError(.missingMessage)
            return
        }
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

    func keepCacheAttributes(
        for folder: Folder,
        using realm: Realm
    ) {
        guard let savedFolder = realm.object(ofType: Folder.self, forPrimaryKey: folder.remoteId) else {
            logError(.missingFolder)
            return
        }
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
}

// MARK: - Equatable conformance

extension MailboxManager: Equatable {
    public static func == (lhs: MailboxManager, rhs: MailboxManager) -> Bool {
        return lhs.mailbox.id == rhs.mailbox.id
    }
}
