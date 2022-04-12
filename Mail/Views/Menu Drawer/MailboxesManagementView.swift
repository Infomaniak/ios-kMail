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

    @State private var mailboxesUnreadCount = [Int: Int]()
    @State private var unfoldDetails = false

    var body: some View {
        DisclosureGroup(isExpanded: $unfoldDetails) {
            VStack(alignment: .leading) {
                ForEach(accountManager.mailboxes.filter { $0.mailboxId != accountManager.currentMailboxId }, id: \.mailboxId) { mailbox in
                    MailboxesManagementButtonView(text: mailbox.email, detail: mailboxesUnreadCount[mailbox.mailboxId]) {
                        accountManager.setCurrentMailboxForCurrentAccount(mailbox: mailbox)
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
        .padding(.top, 20)
        .onAppear {
            Task {
                mailboxesUnreadCount = await getMailboxesUnreadCount()
            }
        }
    }

    // MARK: - Private functions

    private func getMailboxesUnreadCount() async -> [Int: Int] {
        var mailboxesData = [Int: Int]()
        for mailbox in accountManager.mailboxes {
            mailboxesData[mailbox.mailboxId] = try? await accountManager.getMailboxManager(for: mailbox)?.getUnreadMessages()
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
