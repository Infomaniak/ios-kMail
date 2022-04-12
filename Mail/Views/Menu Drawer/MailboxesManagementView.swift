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
    @EnvironmentObject var accountManager: AccountManager

    @State private var mailboxes = [(mailbox: Mailbox, unreadCount: Int)]()
    @State private var unfoldDetails = false

    var body: some View {
        DisclosureGroup(isExpanded: $unfoldDetails) {
            VStack(alignment: .leading) {
                ForEach(mailboxes, id: \.mailbox.mailboxId) { mailboxData in
                    MailboxesManagementButtonView(text: mailboxData.mailbox.email, detail: "\(mailboxData.unreadCount)") {
                        accountManager.setCurrentMailboxForCurrentAccount(mailbox: mailboxData.mailbox)
                    }
                }

                MenuDrawerSeparatorView(withPadding: false, fullWidth: true)

                MailboxesManagementButtonView(text: "Ajouter un compte", handleAction: addNewAccount)
                MailboxesManagementButtonView(text: "Gérer mon compte", handleAction: handleMyAccount)
            }
            .padding(.leading)
            .padding(.top, 5)
        } label: {
            Text(accountManager.currentMailboxManager?.mailbox.email ?? "")
                .fontWeight(.semibold)
                .lineLimit(1)
        }
        .accentColor(Color(MailResourcesAsset.primaryTextColor.color))
        .padding([.top], 20)
        .onAppear {
            Task {
                mailboxes = await getMailboxesData()
            }
        }
    }

    // MARK: - Private functions

    private func getMailboxesData() async -> [(mailbox: Mailbox, unreadCount: Int)] {
        let mailboxes = accountManager.mailboxes.filter { $0.mailboxId != accountManager.currentMailboxId }
        var mailboxesData = [(mailbox: Mailbox, unreadCount: Int)]()
        for mailbox in mailboxes {
            let unreadCount = try? await accountManager.getMailboxManager(for: mailbox)?.getUnreadMessages()
            mailboxesData.append((mailbox, unreadCount ?? 0))
        }
        return mailboxesData
    }

    // MARK: - Menu actions

    private func addNewAccount() {
        // todo later
    }

    private func handleMyAccount() {
        // todo later
    }
}

struct MailboxesManagementView_Previews: PreviewProvider {
    static var previews: some View {
        MailboxesManagementView()
            .previewLayout(.sizeThatFits)
    }
}
