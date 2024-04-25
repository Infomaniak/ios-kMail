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

import Foundation
import InfomaniakCore
import InfomaniakCoreDB
import Realm
import RealmSwift

/// Conforming to `RealmAccessible` to get a standard `.getRealm` function
extension MailboxInfosManager: RealmAccessible {}

public final class MailboxInfosManager {
    private static let currentDbVersion: UInt64 = 7
    public let realmConfiguration: Realm.Configuration
    private let dbName = "MailboxInfos.realm"

    private let backgroundRealm: BackgroundRealm

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
            },
            objectTypes: [Mailbox.self, MailboxPermissions.self, Quotas.self, ExternalMailInfo.self]
        )

        backgroundRealm = BackgroundRealm(configuration: realmConfiguration)
        excludeRealmFromBackup()
    }

    private func initMailboxForRealm(mailbox: Mailbox, userId: Int) {
        mailbox.userId = userId
    }

    @discardableResult
    func storeMailboxes(user: InfomaniakCore.UserProfile, mailboxes: [Mailbox]) async -> [Mailbox] {
        let realm = getRealm()
        for mailbox in mailboxes {
            initMailboxForRealm(mailbox: mailbox, userId: user.id)
            keepCacheAttributes(for: mailbox, using: realm)
        }

        let mailboxRemoved = getMailboxes(for: user.id, using: realm).filter { currentMailbox in
            !mailboxes.contains { newMailbox in
                newMailbox.objectId == currentMailbox.objectId
            }
        }
        let mailboxRemovedIds = mailboxRemoved.map(\.objectId)

        await backgroundRealm.execute { realm in
            let detachedMailboxes = mailboxes.map { $0.detached() }
            try? realm.write {
                realm.delete(realm.objects(Mailbox.self).filter("objectId IN %@", mailboxRemovedIds))
                realm.add(detachedMailboxes, update: .modified)
            }
        }
        return mailboxRemoved
    }

    public static func getObjectId(mailboxId: Int, userId: Int) -> String {
        return "\(mailboxId)_\(userId)"
    }

    public func getMailboxes(for userId: Int? = nil, using realm: Realm? = nil) -> [Mailbox] {
        let realm = realm ?? getRealm()
        var realmMailboxList = realm.objects(Mailbox.self)
            .sorted(by: \Mailbox.mailboxId)
        if let userId {
            realmMailboxList = realmMailboxList.where { $0.userId == userId }
        }
        return Array(realmMailboxList.map { $0.freeze() })
    }

    public func getMailbox(id: Int, userId: Int, using realm: Realm? = nil) -> Mailbox? {
        return getMailbox(objectId: MailboxInfosManager.getObjectId(mailboxId: id, userId: userId), using: realm)
    }

    public func getMailbox(objectId: String, freeze: Bool = true, using realm: Realm? = nil) -> Mailbox? {
        let realm = realm ?? getRealm()
        let mailbox = realm.object(ofType: Mailbox.self, forPrimaryKey: objectId)
        return freeze ? mailbox?.freeze() : mailbox
    }

    public func updateUnseen(unseenMessages: Int, for mailbox: Mailbox) async {
        await backgroundRealm.execute { realm in
            let freshMailbox = mailbox.fresh(using: realm)
            try? realm.safeWrite {
                freshMailbox?.unseenMessages = unseenMessages
            }
        }
    }

    public func keepCacheAttributes(for mailbox: Mailbox, using realm: Realm? = nil) {
        let realm = realm ?? getRealm()
        guard let savedMailbox = realm.object(ofType: Mailbox.self, forPrimaryKey: mailbox.objectId) else { return }
        mailbox.unseenMessages = savedMailbox.unseenMessages
    }

    public func removeMailboxesFor(userId: Int) {
        let realm = getRealm()
        let userMailboxes = realm.objects(Mailbox.self).where { $0.userId == userId }
        try? realm.safeWrite {
            realm.delete(userMailboxes)
        }
    }
}
