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

struct AutocompletionView: View {
    @State private var shouldAddUserProposal = false

    @Binding var autocompletion: [Recipient]
    @Binding var currentSearch: String
    @Binding var addedRecipients: RealmSwift.List<Recipient>

    let addRecipient: @MainActor (Recipient) -> Void

    var body: some View {
        LazyVStack(spacing: UIConstants.autocompletionVerticalPadding) {
            ForEach(autocompletion) { recipient in
                let isLastRecipient = autocompletion.last?.isSameRecipient(as: recipient) == true
                let isUserProposal = shouldAddUserProposal && isLastRecipient

                VStack(alignment: .leading, spacing: UIConstants.autocompletionVerticalPadding) {
                    AutocompletionCell(
                        addRecipient: addRecipient,
                        recipient: recipient,
                        highlight: currentSearch,
                        alreadyAppend: addedRecipients.contains { $0.isSameRecipient(as: recipient) },
                        unknownRecipient: isUserProposal
                    )

                    if !isLastRecipient {
                        IKDivider()
                    }
                }
            }
        }
        .onAppear {
            updateAutocompletion(currentSearch)
        }
        .onChange(of: currentSearch, perform: updateAutocompletion)
    }

    private func updateAutocompletion(_ search: String) {
        guard let contactManager = AccountManager.instance.currentContactManager else {
            withAnimation {
                autocompletion = []
            }
            return
        }

        let trimmedSearch = search.trimmingCharacters(in: .whitespacesAndNewlines)

        let autocompleteContacts = contactManager.contacts(matching: trimmedSearch)
        var autocompleteRecipients = autocompleteContacts.map { Recipient(email: $0.email, name: $0.name) }

        let realResults = autocompleteRecipients.filter { !addedRecipients.map(\.email).contains($0.email) }

        withAnimation {
            shouldAddUserProposal = !(realResults.count == 1 && realResults.first?.email == currentSearch)
            if shouldAddUserProposal {
                autocompleteRecipients.append(Recipient(email: currentSearch, name: ""))
            }

            autocompletion = autocompleteRecipients
        }
    }
}

struct AutocompletionView_Previews: PreviewProvider {
    static var previews: some View {
        AutocompletionView(
            autocompletion: .constant([]),
            currentSearch: .constant(""),
            addedRecipients: .constant([PreviewHelper.sampleRecipient1].toRealmList())
        ) { _ in /* Preview */ }
    }
}
