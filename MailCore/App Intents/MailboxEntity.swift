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
import Foundation
import InfomaniakDI

@available(iOS 18.4, *)
@AppEntity(schema: .mail.mailbox)
public struct MailboxEntity: IndexedEntity {
    // MARK: Static

    public static let defaultQuery = MailboxEntityQuery()

    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Mailbox")
    }

    // MARK: Properties

    public let id: String

    public var name: String
    public var account: MailAccountEntity

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    public init(id: String, name: String, account: MailAccountEntity) {
        self.id = id
        self.name = name
        self.account = account
    }

    public struct MailboxEntityQuery: EntityQuery {
        public init() {}

        public func entities(for identifiers: [MailboxEntity.ID]) async throws -> [MailboxEntity] {
            @InjectService var mailboxInfosManager: MailboxInfosManager
            let idSet = Set(identifiers)
            return mailboxInfosManager.getMailboxes()
                .filter { idSet.contains($0.objectId) }
                .map { MailboxEntity(mailbox: $0) }
        }

        public func suggestedEntities() async throws -> [MailboxEntity] {
            @InjectService var mailboxInfosManager: MailboxInfosManager
            return mailboxInfosManager.getMailboxes().map { MailboxEntity(mailbox: $0) }
        }
    }
}

@available(iOS 18.4, *)
extension MailboxEntity {
    init(mailbox: Mailbox) {
        id = mailbox.objectId
        name = mailbox.email
        account = MailAccountEntity(mailbox: mailbox)
    }
}
