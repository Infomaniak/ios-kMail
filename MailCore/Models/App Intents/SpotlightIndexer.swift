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

import CoreSpotlight
import Foundation
import InfomaniakDI
import OSLog

@available(iOS 18.4, *)
public final class SpotlightIndexer {
    private static let logger = Logger(category: "SpotlightIndexer")

    public static let spotlightIndexName = "Infomaniak Mail"
    public static let maxIndexedMessages = 500

    public init() {}

    public func indexAllMessages() async {
        await deindexAllMessages()
        @InjectService var mailboxInfosManager: MailboxInfosManager
        @InjectService var accountManager: AccountManager

        let date = Date()

        let allMessages: [MailMessageEntity] = mailboxInfosManager.getMailboxes()
            .filter { !$0.isLocked }
            .flatMap { mailbox -> [MailMessageEntity] in
                guard let mailboxManager = accountManager.getMailboxManager(for: mailbox) else { return [] }

                return Array(
                    mailboxManager
                        .fetchResults(ofType: Message.self) { $0 }
                        .sorted(by: \.date, ascending: false)
                        .prefix(Self.maxIndexedMessages)
                        .map { MailMessageEntity(message: $0, mailbox: mailbox) }
                )
            }

        let cappedEntities = allMessages.max(count: Self.maxIndexedMessages) { $0.dateReceived > $1.dateReceived }

        try? await CSSearchableIndex(name: Self.spotlightIndexName).indexAppEntities(cappedEntities)

        Self.logger.info("Indexed \(cappedEntities.count) messages in Spotlight in \(Date().timeIntervalSince(date)) seconds")
    }

    public func indexMessages(_ messages: [Message], mailbox: Mailbox) {
        guard !messages.isEmpty else { return }
        let entities = messages.map { MailMessageEntity(message: $0, mailbox: mailbox) }
        Task {
            try? await CSSearchableIndex(name: Self.spotlightIndexName).indexAppEntities(entities)
        }
    }

    public func deindexMessages(_ messageUids: [MailMessageEntity.Identifier]) {
        guard !messageUids.isEmpty else { return }
        Task {
            try? await CSSearchableIndex(name: Self.spotlightIndexName).deleteAppEntities(
                identifiedBy: messageUids,
                ofType: MailMessageEntity.self
            )
        }
    }

    public func deindexMessagesForMailbox(id: String) async {
        try? await CSSearchableIndex(name: Self.spotlightIndexName).deleteSearchableItems(withDomainIdentifiers: [id])
    }

    public func deindexAllMessages() async {
        try? await CSSearchableIndex(name: Self.spotlightIndexName).deleteAppEntities(ofType: MailMessageEntity.self)
    }
}
