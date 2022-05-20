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
    private static let currentDbVersion: UInt64 = 1
    public let realmConfiguration: Realm.Configuration
    private let dbName = "MailboxInfos.realm"

    private init() {
        realmConfiguration = Realm.Configuration(
            fileURL: MailboxManager.constants.rootDocumentsURL.appendingPathComponent(dbName),
            schemaVersion: MailboxInfosManager.currentDbVersion,
            objectTypes: [Mailbox.self]
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
                newMailbox.mailboxId == currentMailbox.mailboxId
            }
        }
        let mailboxRemovedIds = mailboxRemoved.map(\.mailboxId)
        try? realm.write {
            realm.delete(realm.objects(Mailbox.self).filter("mailboxId IN %@", mailboxRemovedIds))
            realm.add(mailboxes, update: .modified)
        }
        return mailboxRemoved
    }

    public func getMailboxes(for userId: Int? = nil, using realm: Realm? = nil) -> [Mailbox] {
        let realm = realm ?? getRealm()
        var realmMailboxList = realm.objects(Mailbox.self)
            .sorted(byKeyPath: "mailboxId", ascending: true)
        if let userId = userId {
            let filterPredicate: NSPredicate
            filterPredicate = NSPredicate(format: "userId = %d", userId)
            realmMailboxList = realmMailboxList.filter(filterPredicate)
        }
        return Array(realmMailboxList.map { $0.freeze() })
    }

    public func getMailbox(mailboxId: Int, freeze: Bool = true, using realm: Realm? = nil) -> Mailbox? {
        let realm = realm ?? getRealm()
        let mailbox = realm.object(ofType: Mailbox.self, forPrimaryKey: mailboxId)
        return freeze ? mailbox?.freeze() : mailbox
    }
}
