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

import Combine
import InfomaniakCoreSwiftUI
import MailCore
import MailCoreUI
import RealmSwift
import SwiftUI

struct AutocompletionView: View {
    private static let maxAutocompleteCount = 10

    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var shouldAddUserProposal = false

    @ObservedObject var textDebounce: TextDebounce

    @Binding var autocompletion: [Recipient]
    @Binding var addedRecipients: RealmSwift.List<Recipient>

    let addRecipient: @MainActor (Recipient) -> Void

    var body: some View {
        LazyVStack(spacing: IKPadding.small) {
            ForEach(autocompletion) { recipient in
                let isLastRecipient = autocompletion.last?.isSameCorrespondent(as: recipient) == true
                let isUserProposal = shouldAddUserProposal && isLastRecipient

                VStack(alignment: .leading, spacing: IKPadding.small) {
                    AutocompletionCell(
                        addRecipient: addRecipient,
                        recipient: recipient,
                        highlight: textDebounce.text,
                        alreadyAppend: addedRecipients.contains { $0.isSameCorrespondent(as: recipient) },
                        unknownRecipient: isUserProposal
                    )

                    if !isLastRecipient {
                        IKDivider()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await updateAutocompletion(textDebounce.text)
            }
        }
        .onReceive(textDebounce.$text.debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)) { currentValue in
            Task {
                await updateAutocompletion("\(currentValue)")
            }
        }
    }

    private func updateAutocompletion(_ search: String) async {
        let trimmedSearch = search.trimmingCharacters(in: .whitespacesAndNewlines)

        Task { @MainActor in
            let autocompleteContacts = await mailboxManager.contactManager.frozenContactsAsync(
                matching: trimmedSearch,
                fetchLimit: Self.maxAutocompleteCount,
                sorted: sortByRemoteAndName
            )
            var autocompleteRecipients = autocompleteContacts.map { Recipient(email: $0.email, name: $0.name) }

            let realResults = autocompleteRecipients.filter { !addedRecipients.map(\.email).contains($0.email) }

            shouldAddUserProposal = !(realResults.count == 1 && realResults.first?.email == textDebounce.text)
            if shouldAddUserProposal {
                autocompleteRecipients.append(Recipient(email: textDebounce.text, name: ""))
            }
            autocompletion = autocompleteRecipients
        }
    }

    private func sortByRemoteAndName(lhs: MergedContact, rhs: MergedContact) -> Bool {
        if lhs.isRemote != rhs.isRemote {
            return lhs.isRemote && !rhs.isRemote
        } else {
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
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
