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
    @State private var unfoldDetails = false

    var mailbox: Mailbox

    var body: some View {
        DisclosureGroup(isExpanded: $unfoldDetails) {
            VStack(alignment: .leading) {
                ForEach(AccountManager.instance.mailboxes.filter { $0.mailboxId != mailbox.mailboxId }, id: \.mailboxId) { mailbox in
                    MailboxesManagementButtonView(text: mailbox.email, detail: "2", handleAction: switchMailbox)
                }

                MenuDrawerSeparatorView(withPadding: false)

                MailboxesManagementButtonView(text: "Ajouter un compte", handleAction: addNewAccount)
                MailboxesManagementButtonView(text: "Gérer mon compte", handleAction: handleMyAccount)
            }
            .padding(.leading)
            .padding(.top, 5)
        } label: {
            Text(mailbox.email)
                .fontWeight(.semibold)
                .lineLimit(1)
        }
        .accentColor(Color(MailResourcesAsset.primaryTextColor.color))
        .padding([.top], 20)
    }

    // MARK: - Menu actions

    private func switchMailbox() {
        // todo later
    }

    private func addNewAccount() {
        // todo later
    }

    private func handleMyAccount() {
        // todo later
    }
}

struct MailboxesManagementView_Previews: PreviewProvider {
    static var previews: some View {
        MailboxesManagementView(mailbox: PreviewHelper.sampleMailbox)
            .previewLayout(.sizeThatFits)
    }
}
