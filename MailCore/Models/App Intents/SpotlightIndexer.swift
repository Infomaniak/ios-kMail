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
import MailCore

@available(iOS 18.4, *)
enum SpotlightIndexer {
    static let spotlightIndexName = "Infomaniak Mail"

    static func indexAllMessages() async {
        @InjectService var mailboxInfosManager: MailboxInfosManager
        @InjectService var accountManager: AccountManager

        let date = Date()
        var totalCount = 0

        for mailbox in mailboxInfosManager.getMailboxes() {
            guard let mailboxManager = accountManager.getMailboxManager(for: mailbox) else { continue }

            let messages = Array(mailboxManager.fetchResults(ofType: Message.self) { $0 }.sorted(by: \.date, ascending: false)
                .prefix(1000))

            let entities = messages.map { MailAppIntentsHelper.mapMessage($0, mailbox: mailbox) }

            try? await CSSearchableIndex(name: spotlightIndexName).indexAppEntities(entities)

            totalCount += entities.count
        }

        print("Spotlight: Indexed \(totalCount) messages in \(Date().timeIntervalSince(date)) seconds.")
    }

    static func indexMessages(_ entities: [MailMessageEntity]) {
        guard !entities.isEmpty else { return }
        Task {
            try? await CSSearchableIndex(name: Self.spotlightIndexName).indexAppEntities(entities)
        }
    }

    static func deindexMessages(_ messageUids: [String], mailboxObjectId: String) {
        guard !messageUids.isEmpty else { return }
        let entityIds = messageUids.map { "\(mailboxObjectId)-\($0)" }
        Task {
            try? await CSSearchableIndex(name: Self.spotlightIndexName).deleteAppEntities(
                identifiedBy: entityIds,
                ofType: MailMessageEntity.self
            )
        }
    }

    static func deindexAllMessages() {
        Task {
            try? await CSSearchableIndex(name: Self.spotlightIndexName).deleteAppEntities(ofType: MailMessageEntity.self)
        }
    }
}
