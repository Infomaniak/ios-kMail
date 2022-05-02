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

import InfomaniakCore
import MailResources
import MailCore
import SwiftUI

struct MailboxesManagementView: View {
    @EnvironmentObject var mailboxManager: MailboxManager

    @State private var unfoldDetails = false

    var body: some View {
        DisclosureGroup(isExpanded: $unfoldDetails) {
            VStack(alignment: .leading) {
                ForEach(AccountManager.instance.mailboxes.filter { $0.mailboxId != mailboxManager.mailbox.mailboxId }, id: \.mailboxId) { mailbox in
                    MailboxCell(mailbox: mailbox)
                }

                SeparatorView(withPadding: false, fullWidth: true)

                MailboxesManagementButtonView(text: MailResourcesStrings.buttonAddAccount, handleAction: addNewAccount)
                MailboxesManagementButtonView(text: MailResourcesStrings.buttonManageAccount, handleAction: handleMyAccount)
            }
            .padding(.leading)
            .padding(.top, 5)
        } label: {
            Text(mailboxManager.mailbox.email)
                .fontWeight(.semibold)
                .lineLimit(1)
        }
        .accentColor(Color(MailResourcesAsset.primaryTextColor.color))
        .padding(.top, 20)
    }

    // MARK: - Menu actions

    private func addNewAccount() {
        // TODO: Add new account
    }

    private func handleMyAccount() {
        // TODO: Handle my account
    }
}

struct MailboxesManagementView_Previews: PreviewProvider {
    static var previews: some View {
        MailboxesManagementView()
            .previewLayout(.sizeThatFits)
    }
}
