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

@available(iOS 27.0, *)
extension MailMessageEntity.MailMessageEntityQuery: IndexedEntityQuery {
    public func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
        @InjectService var mailboxInfosManager: MailboxInfosManager
        @InjectService var accountManager: AccountManager

        let mailboxes = mailboxInfosManager.getMailboxes()

        for mailbox in mailboxes {
            guard let mailboxManager = accountManager.getMailboxManager(for: mailbox) else {
                return
            }
            let messages = Array(mailboxManager.fetchResults(ofType: Message.self) { $0 }
                .map { MailMessageEntity(message: $0, mailbox: mailbox) })

            try await CSSearchableIndex(name: SpotlightIndexer.spotlightIndexName).indexAppEntities(messages)
        }
    }

    public func reindexEntities(for identifiers: [MailMessageEntity.Identifier],
                                indexDescription: CSSearchableIndexDescription) async throws {
        @InjectService var mailboxInfosManager: MailboxInfosManager
        @InjectService var accountManager: AccountManager

        let messageEntities: [MailMessageEntity] = identifiers.compactMap {
            guard let mailbox = mailboxInfosManager.getMailbox(objectId: $0.mailboxId),
                  let mailboxManager = accountManager.getMailboxManager(for: mailbox),
                  let message = mailboxManager.fetchObject(ofType: Message.self, forPrimaryKey: $0.messageId) else {
                return nil
            }

            return MailMessageEntity(message: message, mailbox: mailbox)
        }

        try await CSSearchableIndex(name: SpotlightIndexer.spotlightIndexName).indexAppEntities(messageEntities)
    }
}
