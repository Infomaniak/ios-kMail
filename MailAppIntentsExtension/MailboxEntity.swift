/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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

import AppIntents
import InfomaniakDI
import MailCore

@available(iOS 18.0, *)
@AppEntity(schema: .mail.mailbox)
struct MailboxEntity: IndexedEntity {
    // MARK: Static

    static let defaultQuery = MailboxEntityQuery()

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Mailbox")
    }

    // MARK: Properties

    let id: String

    var name: String
    var account: MailAccountEntity

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    init(id: String, name: String, account: MailAccountEntity) {
        self.id = id
        self.name = name
        self.account = account
    }

    // MARK: Query

    struct MailboxEntityQuery: EntityQuery {
        func entities(for identifiers: [MailboxEntity.ID]) async throws -> [MailboxEntity] {
            @InjectService var mailboxInfosManager: MailboxInfosManager
            return mailboxInfosManager.getMailboxes()
                .filter { identifiers.contains($0.objectId) }
                .map { Self.mapMailbox($0) }
        }

        func suggestedEntities() async throws -> [MailboxEntity] {
            @InjectService var mailboxInfosManager: MailboxInfosManager
            return mailboxInfosManager.getMailboxes().map { Self.mapMailbox($0) }
        }

        private static func mapMailbox(_ mailbox: Mailbox) -> MailboxEntity {
            MailboxEntity(
                id: mailbox.objectId,
                name: mailbox.email,
                account: MailAccountEntity(
                    id: mailbox.objectId,
                    name: mailbox.mailbox,
                    emailAddress: mailbox.email
                )
            )
        }
    }
}
