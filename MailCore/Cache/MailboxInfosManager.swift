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
import Realm
import RealmSwift
import Sentry

public class MailboxInfosManager {
    public static let instance = MailboxInfosManager()
    private static let currentDbVersion: UInt64 = 2
    public let realmConfiguration: Realm.Configuration
    private let dbName = "MailboxInfos.realm"

    private init() {
        realmConfiguration = Realm.Configuration(
            fileURL: MailboxManager.constants.rootDocumentsURL.appendingPathComponent(dbName),
            schemaVersion: MailboxInfosManager.currentDbVersion,
            objectTypes: [Mailbox.self, MailboxPermissions.self]
        )
        print(MailboxManager.constants.rootDocumentsURL.path)
    }

    public func getRealm() -> Realm {
        do {
            return try Realm(configuration: realmConfiguration)
        } catch {
            // We can't recover from this error but at least we report it correctly on Sentry
            Logging.reportRealmOpeningError(error, realmConfiguration: realmConfiguration)
        }
    }

    private func initMailboxForRealm(mailbox: Mailbox, userId: Int) {
        mailbox.userId = userId
    }

    @discardableResult
    func storeMailboxes(user: InfomaniakCore.UserProfile, mailboxes: [Mailbox]) -> [Mailbox] {
        for mailbox in mailboxes {
            initMailboxForRealm(mailbox: mailbox, userId: user.id)
        }

        let realm = getRealm()
        let mailboxRemoved = getMailboxes(for: user.id, using: realm).filter { currentMailbox in
            !mailboxes.contains { newMailbox in
                newMailbox.objectId == currentMailbox.objectId
            }
        }
        let mailboxRemovedIds = mailboxRemoved.map(\.objectId)
        try? realm.write {
            realm.delete(realm.objects(Mailbox.self).filter("objectId IN %@", mailboxRemovedIds))
            realm.add(mailboxes, update: .modified)
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
        if let userId = userId {
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
}
