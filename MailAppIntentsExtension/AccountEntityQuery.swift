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

import AppIntents
import Foundation
import InfomaniakDI
import MailCore

struct AccountEntityQuery: EntityQuery {
    func entities(for identifiers: [AccountEntity.ID]) async throws -> [AccountEntity] {
        @InjectService var mailboxInfosManager: MailboxInfosManager

        let matchingMailboxes = mailboxInfosManager.getMailboxes().filter { identifiers.contains($0.objectId) }
        return matchingMailboxes.map { AccountEntity(id: $0.objectId, mailbox: $0.email) }
    }

    func suggestedEntities() async throws -> [AccountEntity] {
        @InjectService var mailboxInfosManager: MailboxInfosManager

        return mailboxInfosManager.getMailboxes().map { AccountEntity(id: $0.objectId, mailbox: $0.email) }
    }
}
