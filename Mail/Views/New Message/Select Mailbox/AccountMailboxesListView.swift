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

    @EnvironmentObject private var mailboxManager: MailboxManager

    let account: Account
    var selectedMailbox: Mailbox?

    let selectMailbox: (Mailbox) -> Void

    private var currentMailbox: Mailbox? {
        return accountManager.currentMailboxManager?.mailbox
    }

    var body: some View {
        Menu {
            ForEachMailboxView(userId: account.userId) { mailbox in
                AccountMailboxCell(mailbox: mailbox, selectedMailbox: selectedMailbox, selectMailbox: selectMailbox)
            }
        } label: {
            HStack(spacing: UIPadding.small) {
                AvatarView(mailboxManager: mailboxManager, contactConfiguration: .user(user: account.user), size: 40)
                VStack(alignment: .leading, spacing: 0) {
                    Text(account.user.displayName)
                        .textStyle(.bodyMedium)
                    Text(account.user.email)
                        .textStyle(.bodySecondary)
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

                ChevronIcon(direction: .down)
            }
            .padding([.leading, .vertical], value: .small)
            .padding(.trailing, value: .regular)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(MailResourcesAsset.elementsColor.swiftUIColor, lineWidth: 1)
            }
        }
    }
}

#Preview {
    AccountMailboxesListView(
        account: PreviewHelper.sampleAccount,
        selectedMailbox: PreviewHelper.sampleMailbox
    ) { _ in }
}
