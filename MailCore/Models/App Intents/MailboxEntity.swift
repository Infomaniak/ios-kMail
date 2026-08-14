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
import CoreSpotlight
import Foundation
import InfomaniakDI
import MailCore

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

    public struct MailboxEntityQuery: IndexedEntityQuery {
        public init() {}

        public func entities(for identifiers: [MailboxEntity.ID]) async throws -> [MailboxEntity] {
            @InjectService var mailboxInfosManager: MailboxInfosManager
            let idSet = Set(identifiers)
            return mailboxInfosManager.getMailboxes()
                .filter { idSet.contains($0.objectId) }
                .map { MailAppIntentsHelper.mapMailbox($0) }
        }

        public func suggestedEntities() async throws -> [MailboxEntity] {
            @InjectService var mailboxInfosManager: MailboxInfosManager
            return mailboxInfosManager.getMailboxes().map { MailAppIntentsHelper.mapMailbox($0) }
        }

        @available(iOS 27.0, *)
        public func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
            @InjectService var mailboxInfosManager: MailboxInfosManager
            @InjectService var accountManager: AccountManager
            let mailboxes = mailboxInfosManager.getMailboxes()
            for mailbox in mailboxes {
                guard let mailboxManager = accountManager.getMailboxManager(for: mailbox) else {
                    return
                }
                let messages = Array(mailboxManager.fetchResults(ofType: Message.self) { $0 }
                    .map {
                        MailAppIntentsHelper.mapMessage(
                            $0,
                            mailbox: mailbox
                        )
                    })
                try await CSSearchableIndex(name: "Infomaniak Mail").indexAppEntities(messages)
            }
        }

        @available(iOS 27.0, *)
        public func reindexEntities(for identifiers: [String], indexDescription: CSSearchableIndexDescription) async throws {
            @InjectService var mailboxInfosManager: MailboxInfosManager
            @InjectService var accountManager: AccountManager
            let mailboxes = mailboxInfosManager.getMailboxes()
            for mailbox in mailboxes {
                guard let mailboxManager = accountManager.getMailboxManager(for: mailbox) else {
                    return
                }
                let messages = Array(mailboxManager.fetchResults(ofType: Message.self) { $0 }
                    .filter { identifiers.contains($0.uid) }
                    .map {
                        MailAppIntentsHelper.mapMessage(
                            $0,
                            mailbox: mailbox
                        )
                    })
                try await CSSearchableIndex(name: "Infomaniak Mail").indexAppEntities(messages)
            }
        }
    }
}
