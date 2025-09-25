/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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
import Realm
import RealmSwift

// So we can exclude it from backups
extension MailboxInfosManager: RealmConfigurable {}

public final class MailboxInfosManager {
    private static let currentDbVersion: UInt64 = 14
    private let dbName = "MailboxInfos.realm"

    public let realmConfiguration: Realm.Configuration
    public let transactionExecutor: Transactionable

    public init() {
        realmConfiguration = Realm.Configuration(
            fileURL: MailboxManager.constants.rootDocumentsURL.appendingPathComponent(dbName),
            schemaVersion: MailboxInfosManager.currentDbVersion,
            migrationBlock: { migration, oldSchemaVersion in
                // No migration needed from 0 to 5

                // Added `aliases` to Mailbox
                if oldSchemaVersion < 6 {
                    migration.enumerateObjects(ofType: Mailbox.className()) { _, newObject in
                        newObject!["aliases"] = List<String>()
                    }
                }

                // Renamed `isValid` to `isValidInLDAP`
                if oldSchemaVersion < 8 {
                    migration.enumerateObjects(ofType: Mailbox.className()) { oldObject, newObject in
                        newObject!["isValidInLDAP"] = oldObject!["isValid"]
                    }
                }
            },
            objectTypes: [
                Mailbox.self,
                MailboxPermissions.self,
                Quotas.self,
                ExternalMailInfo.self,
                SendersRestrictions.self,
                Sender.self
            ]
        )

        let realmAccessor = MailCoreRealmAccessor(realmConfiguration: realmConfiguration)
        transactionExecutor = TransactionExecutor(realmAccessible: realmAccessor)

        excludeRealmFromBackup()
    }

    private func initMailboxForRealm(mailbox: Mailbox, userId: Int) {
        mailbox.userId = userId
    }

    @discardableResult
    func storeMailboxes(user: InfomaniakCore.UserProfile, mailboxes: [Mailbox]) async -> [Mailbox] {
        var mailboxRemoved = [Mailbox]()
        var mailboxRemovedIds = [String]()
        try? writeTransaction { writableRealm in
            for mailbox in mailboxes {
                initMailboxForRealm(mailbox: mailbox, userId: user.id)
                keepCacheAttributes(for: mailbox, writableRealm: writableRealm)
            }

            mailboxRemoved = getMailboxes(for: user.id, using: writableRealm).filter { currentMailbox in
                !mailboxes.contains { newMailbox in
                    newMailbox.objectId == currentMailbox.objectId
                }
            }

            mailboxRemovedIds = mailboxRemoved.map(\.objectId)

            let detachedMailboxes = mailboxes.map { $0.detached() }
            let mailboxes = writableRealm.objects(Mailbox.self).filter("objectId IN %@", mailboxRemovedIds)
            writableRealm.delete(mailboxes)
            writableRealm.add(detachedMailboxes, update: .modified)
        }

        return mailboxRemoved
    }

    public static func getObjectId(mailboxId: Int, userId: Int) -> String {
        return "\(mailboxId)_\(userId)"
    }

    public func getMailboxes(for userId: Int? = nil) -> [Mailbox] {
        let mailboxes = fetchResults(ofType: Mailbox.self) { partial in
            var realmMailboxList = partial.sorted(by: \Mailbox.mailboxId)

            if let userId {
                realmMailboxList = realmMailboxList.where { $0.userId == userId }
            }

            let frozenMailboxes = realmMailboxList.freezeIfNeeded()
            return frozenMailboxes
        }

        return Array(mailboxes)
    }

    public func getMailboxes(for userId: Int? = nil, using realm: Realm) -> [Mailbox] {
        var realmMailboxList = realm.objects(Mailbox.self)
            .sorted(by: \Mailbox.mailboxId)
        if let userId {
            realmMailboxList = realmMailboxList.where { $0.userId == userId }
        }

        return Array(realmMailboxList.map { $0.freeze() })
    }

    public func getMailbox(id: Int, userId: Int) -> Mailbox? {
        return getMailbox(objectId: MailboxInfosManager.getObjectId(mailboxId: id, userId: userId))
    }

    public func getMailbox(id: Int, userId: Int, using realm: Realm) -> Mailbox? {
        return getMailbox(objectId: MailboxInfosManager.getObjectId(mailboxId: id, userId: userId), using: realm)
    }

    public func getMailbox(objectId: String, freeze: Bool = true) -> Mailbox? {
        let mailbox = fetchObject(ofType: Mailbox.self, forPrimaryKey: objectId)
        return freeze ? mailbox?.freeze() : mailbox
    }

    public func getMailbox(objectId: String, freeze: Bool = true, using realm: Realm) -> Mailbox? {
        let mailbox = realm.object(ofType: Mailbox.self, forPrimaryKey: objectId)
        return freeze ? mailbox?.freeze() : mailbox
    }

    public func updateUnseen(unseenMessages: Int, for mailbox: Mailbox) async {
        try? writeTransaction { writableRealm in
            let freshMailbox = mailbox.fresh(using: writableRealm)
            freshMailbox?.unseenMessages = unseenMessages
        }
    }

    public func keepCacheAttributes(for mailbox: Mailbox, writableRealm: Realm) {
        guard let savedMailbox = writableRealm.object(ofType: Mailbox.self, forPrimaryKey: mailbox.objectId) else { return }
        mailbox.unseenMessages = savedMailbox.unseenMessages
    }

    public func removeMailboxesFor(userId: Int) {
        try? writeTransaction { writableRealm in
            let userMailboxes = writableRealm.objects(Mailbox.self).where { $0.userId == userId }
            writableRealm.delete(userMailboxes)
        }
    }

    public func updateSendersRestrictions(mailboxObjectId: String, sendersRestrictions: SendersRestrictions) {
        guard let mailbox = getMailbox(objectId: mailboxObjectId, freeze: false) else { return }
        try? writeTransaction { _ in
            mailbox.sendersRestrictions = sendersRestrictions
        }
    }

    public func updateSpamFilter(mailboxObjectId: String, value: Bool) {
        guard let mailbox = getMailbox(objectId: mailboxObjectId, freeze: false) else { return }
        try? writeTransaction { _ in
            mailbox.isSpamFilter = value
        }
    }
}
