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

import MailCore
import RealmSwift
import SwiftUI

struct AutocompletionViewV2: View {
    @State private var recipients = [Recipient]()

    @Binding var currentSearch: String
    @Binding var addedRecipients: RealmSwift.List<Recipient>

    var body: some View {
        LazyVStack {
            ForEach(recipients) { recipient in
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        addedRecipients.append(recipient)
                    } label: {
                        RecipientCell(recipient: recipient)
                    }
                    .padding(.horizontal, 8)

                    IKDivider()
                }
            }
        }
        .onChange(of: currentSearch, perform: updateAutocompletion)
    }

    private func updateAutocompletion(_ search: String) {
        let trimmedSearch = search.trimmingCharacters(in: .whitespacesAndNewlines)

        print("coucou")

        guard let contactManager = AccountManager.instance.currentContactManager else {
            withAnimation {
                recipients = []
            }
            return
          }

        let autocompleteContacts = contactManager.contacts(matching: trimmedSearch)
        let autocompleteRecipients = autocompleteContacts.map { Recipient(email: $0.email, name: $0.name) }

        withAnimation {
            recipients = autocompleteRecipients
        }
    }
}

struct AutocompletionViewV2_Previews: PreviewProvider {
    static var previews: some View {
        AutocompletionViewV2(
            currentSearch: .constant(""),
            addedRecipients: .constant([PreviewHelper.sampleRecipient1].toRealmList())
        )
    }
}
