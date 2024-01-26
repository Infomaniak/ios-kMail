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

import Combine
import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct AutocompletionView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var shouldAddUserProposal = false

    @ObservedObject var textDebounce: TextDebounce

    @Binding var autocompletion: [Recipient]
    @Binding var addedRecipients: RealmSwift.List<Recipient>

    let addRecipient: @MainActor (Recipient) -> Void

    var body: some View {
        LazyVStack(spacing: UIPadding.small) {
            ForEach(autocompletion) { recipient in
                let isLastRecipient = autocompletion.last?.isSameRecipient(as: recipient) == true
                let isUserProposal = shouldAddUserProposal && isLastRecipient

                VStack(alignment: .leading, spacing: UIPadding.small) {
                    AutocompletionCell(
                        addRecipient: addRecipient,
                        recipient: recipient,
                        highlight: textDebounce.text,
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
            updateAutocompletion(textDebounce.text)
        }
        .onReceive(textDebounce.$text.debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)) { currentValue in
            updateAutocompletion("\(currentValue)")
        }
    }

    private func updateAutocompletion(_ search: String) {
        let trimmedSearch = search.trimmingCharacters(in: .whitespacesAndNewlines)

        let autocompleteContacts = mailboxManager.contactManager.frozenContacts(matching: trimmedSearch)
        var autocompleteRecipients = autocompleteContacts.map { Recipient(email: $0.email, name: $0.name) }

        let realResults = autocompleteRecipients.filter { !addedRecipients.map(\.email).contains($0.email) }

        withAnimation {
            shouldAddUserProposal = !(realResults.count == 1 && realResults.first?.email == textDebounce.text)
            if shouldAddUserProposal {
                autocompleteRecipients
                    .append(Recipient(email: textDebounce.text, name: ""))
            }

            autocompletion = autocompleteRecipients
        }
    }
}

#Preview {
    AutocompletionView(
        textDebounce: TextDebounce(),
        autocompletion: .constant([]),
        addedRecipients: .constant(PreviewHelper.sampleRecipientsList)
    ) { _ in /* Preview */ }
}
