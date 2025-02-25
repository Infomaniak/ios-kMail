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
import InfomaniakDI
import OSLog
import RealmSwift
import SwiftRegex

public final class MailboxManager: ObservableObject, MailboxManageable {
    @LazyInjectService var mailboxInfosManager: MailboxInfosManager

    lazy var refreshActor = RefreshActor(mailboxManager: self)

    public static let constants = MailboxManagerConstants()

    public let realmConfiguration: Realm.Configuration
    public let transactionExecutor: Transactionable

    public let mailbox: Mailbox

    public let apiFetcher: MailApiFetcher
    public let contactManager: ContactManageable

    enum ErrorDomain: Error {
        case missingFolder
        case missingDraft
        case tooManyDiffs
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

            let groupDirectoryURLBefore = groupDirectoryURL
            Logger.general.info("groupDirectoryURLBefore: \(groupDirectoryURLBefore)")

            let fileManagerUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.absoluteString ?? ""
            Logger.general.info("App working path is: \(fileManagerUrl)")

            let groupDirectoryURLAfter = groupDirectoryURL.absoluteString
            Logger.general.info("Group container path is: \(groupDirectoryURLAfter)")
        }
    }

    public init(mailbox: Mailbox, apiFetcher: MailApiFetcher, contactManager: ContactManageable) {
        self.mailbox = mailbox
        self.apiFetcher = apiFetcher
        self.contactManager = contactManager
        let realmName = "\(mailbox.userId)-\(mailbox.mailboxId).realm"
        realmConfiguration = Realm.Configuration(
            fileURL: MailboxManager.constants.rootDocumentsURL.appendingPathComponent(realmName),
            schemaVersion: 46,
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
                if oldSchemaVersion < 37 {
                    migration.enumerateObjects(ofType: Message.className()) { oldObject, newObject in
                        newObject?["internalDate"] = oldObject?["date"]
                    }
                    migration.enumerateObjects(ofType: Thread.className()) { oldObject, newObject in
                        newObject?["internalDate"] = oldObject?["date"]
                    }
                }
                if oldSchemaVersion < 39 {
                    let snoozeUUIDParser = SnoozeUUIDParser()

                    migration.enumerateObjects(ofType: Message.className()) { oldObject, newObject in
                        if oldObject?.objectSchema["snoozeAction"] != nil,
                           let snoozeAction = oldObject?["snoozeAction"] as? String {
                            newObject?["snoozeUuid"] = snoozeUUIDParser.parse(resource: snoozeAction)
                        }
                    }
                    migration.enumerateObjects(ofType: Thread.className()) { oldObject, newObject in
                        if oldObject?.objectSchema["snoozeAction"] != nil,
                           let snoozeAction = oldObject?["snoozeAction"] as? String {
                            newObject?["snoozeUuid"] = snoozeUUIDParser.parse(resource: snoozeAction)
                        }
                    }
                }
                if oldSchemaVersion < 46 {
                    migration.deleteData(forType: Folder.className())
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
                RecipientsList.self,
                Draft.self,
                Signature.self,
                SearchHistory.self,
                CalendarEventResponse.self,
                CalendarEvent.self,
                Attendee.self,
                Bimi.self,
                SwissTransferAttachment.self,
                File.self,
                MessageUid.self,
                MessageHeaders.self,
                BookableResource.self,
                MessageReaction.self,
                ReactionAuthor.self
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
                    Logger.general.info("Deleting file: \(file.lastPathComponent)")
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
        static let reactions = MessagePropertiesOptions(rawValue: 1 << 4)

        static let standard: MessagePropertiesOptions = [.fullyDownloaded, .body, .attachments, .localSafeDisplay, .reactions]
    }

    func keepCacheAttributes(
        for message: Message,
        keepProperties: MessagePropertiesOptions,
        using realm: Realm
    ) {
        guard let savedMessage = realm.object(ofType: Message.self, forPrimaryKey: message.uid) else {
            return
        }
        message.inTrash = savedMessage.inTrash
        if keepProperties.contains(.fullyDownloaded) {
            message.fullyDownloaded = savedMessage.fullyDownloaded
        }
        if keepProperties.contains(.body), let body = savedMessage.body {
            message.body = body.detached()
        }
        if keepProperties.contains(.localSafeDisplay) {
            message.localSafeDisplay = savedMessage.localSafeDisplay
        }
        if keepProperties.contains(.attachments) {
            let attachments = savedMessage.attachments.map { $0.detached() }
            let attachmentsList = List<Attachment>()
            attachmentsList.append(objectsIn: attachments)
            message.attachments = attachmentsList
        }
        if keepProperties.contains(.reactions) {
            message.reactions = savedMessage.reactions.detached()
        }
    }

    func keepCacheAttributes(
        for folder: Folder,
        using realm: Realm
    ) {
        guard let savedFolder = realm.object(ofType: Folder.self, forPrimaryKey: folder.remoteId) else {
            return
        }
        folder.unreadCount = savedFolder.unreadCount
        folder.lastUpdate = savedFolder.lastUpdate
        folder.cursor = savedFolder.cursor
        folder.remainingOldMessagesToFetch = savedFolder.remainingOldMessagesToFetch
        folder.oldMessagesUidsToFetch = savedFolder.oldMessagesUidsToFetch.detached()
        folder.newMessagesUidsToFetch = savedFolder.newMessagesUidsToFetch.detached()
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

    public func getThread(from threadId: String) -> Thread? {
        guard let thread = transactionExecutor.fetchObject(ofType: Thread.self, forPrimaryKey: threadId) else { return nil }
        return thread.freezeIfNeeded()
    }

    private func refreshSendersRestrictions() async throws -> SendersRestrictions {
        let sendersRestrictions = try await apiFetcher.sendersRestrictions(mailbox: mailbox)
        mailboxInfosManager.updateSendersRestrictions(mailboxObjectId: mailbox.objectId, sendersRestrictions: sendersRestrictions)
        return sendersRestrictions
    }

    public func unblockSender(sender: String) async throws {
        let sendersRestrictions = try await refreshSendersRestrictions().detached()

        guard let indexToRemove = sendersRestrictions.blockedSenders.firstIndex(where: { $0.email == sender }) else { return }
        sendersRestrictions.blockedSenders.remove(at: indexToRemove)

        _ = try await apiFetcher.updateSendersRestrictions(mailbox: mailbox, sendersRestrictions: sendersRestrictions)

        mailboxInfosManager.updateSendersRestrictions(mailboxObjectId: mailbox.objectId, sendersRestrictions: sendersRestrictions)
    }

    public func activateSpamFilter() async throws {
        _ = try? await apiFetcher.updateSpamFilter(mailbox: mailbox, value: true)
        mailboxInfosManager.updateSpamFilter(mailboxObjectId: mailbox.objectId, value: true)
    }
}

// MARK: - Equatable conformance

extension MailboxManager: Equatable {
    public static func == (lhs: MailboxManager, rhs: MailboxManager) -> Bool {
        return lhs.mailbox.id == rhs.mailbox.id
    }
}
