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
import MailCore
import SwiftUI

struct MailboxesManagementView: View {
    @State private var unfoldDetails = false

    var mailbox: Mailbox

    var body: some View {
        DisclosureGroup(isExpanded: $unfoldDetails) {
            VStack(alignment: .leading) {
                ForEach(AccountManager.instance.mailboxes.filter { $0.mailboxId != mailbox.mailboxId }, id: \.mailboxId) { mailbox in
                    Button {
                        print("Update account")
                    } label: {
                        Text(mailbox.email)
                        Spacer()
                        Text("2")
                            .foregroundColor(Color(InfomaniakCoreAsset.infomaniakColor.color))
                    }
                    .padding([.top, .bottom], 3)
                }

                Divider()

                Button("Ajouter un compte") {}
                    .padding(.top, 5)
                Button("Gérer mon compte") {}
                    .padding(.top, 5)
            }
            .padding(.leading)
        } label: {
            Text(mailbox.email)
                .fontWeight(.semibold)
                .lineLimit(1)
        }
        .accentColor(.primary)
        .padding([.leading, .trailing], MenuDrawerView.horizontalPadding)
        .padding([.top], 20)
        .padding([.bottom], 15)
    }
}

struct MailboxesManagementView_Previews: PreviewProvider {
    static var previews: some View {
        MailboxesManagementView(mailbox: PreviewHelper.sampleMailbox)
            .previewLayout(.sizeThatFits)
    }
}
