/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import InfomaniakCore
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct AccountMailboxesListView: View {
    @LazyInjectService private var accountManager: AccountManager

    var accounts: [Account]
    var selectedMailbox: Mailbox?
    var selectMailbox: (Mailbox) -> Void

    var body: some View {
        ForEach(accounts) { account in
            Text(account.user.displayName)

            if account.userId == accountManager.currentUserId,
               let currentMailbox = accountManager.currentMailboxManager?.mailbox {
                MailboxesManagementButtonView(
                    icon: MailResourcesAsset.envelope,
                    mailbox: currentMailbox,
                    isSelected: selectedMailbox?.id == currentMailbox.id
                ) {
                    selectMailbox(currentMailbox)
                }
            }

            ForEachMailboxView(
                userId: account.userId,
                excludedMailboxIds: [accountManager.currentMailboxManager?.mailbox.mailboxId].compactMap { $0 }
            ) { mailbox in
                MailboxesManagementButtonView(
                    icon: MailResourcesAsset.envelope,
                    mailbox: mailbox,
                    isSelected: selectedMailbox?.id == mailbox.id
                ) {
                    selectMailbox(mailbox)
                }
            }
        }
    }
}

#Preview {
    AccountMailboxesListView(accounts: [], selectedMailbox: PreviewHelper.sampleMailbox) { _ in }
}
