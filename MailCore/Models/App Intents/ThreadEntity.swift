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
import MailCore

@available(iOS 27.0, *)
@AppEntity(schema: .mail.thread)
public struct MailThreadEntity: IndexedEntity {
    // MARK: Static

    public static let defaultQuery = MailThreadEntityQuery()

    // MARK: Properties

    public let id: String

    public var title: String
    public var description: String?
    public var messages: [MailMessageEntity]

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(description ?? "")")
    }

    public init(id: String, title: String, description: String? = nil, messages: [MailMessageEntity]) {
        self.id = id
        self.title = title
        self.description = description
        self.messages = messages
    }

    // MARK: Query

    public struct MailThreadEntityQuery: EntityQuery {
        public init() {}
        public func entities(for identifiers: [MailThreadEntity.ID]) async throws -> [MailThreadEntity] {
            @InjectService var mailboxInfosManager: MailboxInfosManager
            @InjectService var accountManager: AccountManager

            let mailboxes = mailboxInfosManager.getMailboxes()
            return mailboxes.flatMap { mailbox -> [MailThreadEntity] in
                guard let mailboxManager = accountManager.getMailboxManager(for: mailbox) else {
                    return []
                }

                let threads = mailboxManager.fetchResults(ofType: Thread.self) {
                    $0.filter(NSPredicate(format: "uid IN %@", identifiers))
                }
                return threads.map { MailAppIntentsHelper.mapThread($0, mailbox: mailbox) }
            }
        }
    }
}
