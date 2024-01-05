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

struct AccountOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> ItemCollection<AccountEntity> {
        @InjectService var accountManager: AccountManager
        @InjectService var mailboxInfosManager: MailboxInfosManager

        var accountSections = [ItemSection]()
        let groupedMailboxes = Dictionary(grouping: mailboxInfosManager.getMailboxes(), by: \.userId)
        for group in groupedMailboxes {
            let accountName = accountManager.accounts.first { $0.userId == group.key }?.user?.email
            accountSections.append(IntentItemSection(
                "\(accountName ?? "")",
                items: group.value.map { AccountEntity(id: $0.objectId, mailbox: $0.email) }
            ))
        }

        return ItemCollection(sections: accountSections)
    }
}
