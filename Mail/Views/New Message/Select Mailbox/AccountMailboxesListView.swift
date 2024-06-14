/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import InfomaniakCore
import InfomaniakDI
import MailCore
import MailCoreUI
import SwiftUI

struct AccountMailboxesListView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    let account: Account
    var selectedMailbox: Mailbox?

    let selectMailbox: (Mailbox) -> Void

    var body: some View {
        Menu {
            ForEachMailboxView(userId: account.userId) { mailbox in
                AccountMailboxCell(mailbox: mailbox, selectedMailbox: selectedMailbox, selectMailbox: selectMailbox)
            }
        } label: {
            AccountHeaderCell(
                account: account,
                mailboxManager: mailboxManager,
                isSelected: .constant(false),
                type: .selectComposeMailbox
            )
        }
    }
}

#Preview {
    AccountMailboxesListView(
        account: PreviewHelper.sampleAccount,
        selectedMailbox: PreviewHelper.sampleMailbox
    ) { _ in }
}
