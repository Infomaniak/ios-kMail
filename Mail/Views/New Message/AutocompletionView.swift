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
import DesignSystem
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

    @Binding var autocompletion: [any ContactAutocompletable]
    @Binding var addedRecipients: RealmSwift.List<Recipient>

    let addRecipient: @MainActor (any ContactAutocompletable) -> Void

    var body: some View {
        LazyVStack(spacing: IKPadding.mini) {
            ForEach(autocompletion, id: \.contactId) { contact in
                let isLastRecipient = autocompletion.last?.isSameContactAutocompletable(as: contact) == true
                let isUserProposal = shouldAddUserProposal && isLastRecipient

                VStack(alignment: .leading, spacing: IKPadding.mini) {
                    AutocompletionCell(
                        addRecipient: addRecipient,
                        autocompletion: contact,
                        highlight: textDebounce.text,
                        alreadyAppend: addedRecipients.contains { $0.isEquivalent(to: contact) },
                        unknownRecipient: isUserProposal
                    )

                    if !isLastRecipient {
                        IKDivider()
                    }
                }
            }
        }
        .task {
            await updateAutocompletion(textDebounce.text)
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
            let combinedResults = await mailboxManager.contactManager.searchAllAutocompletable(
                matching: trimmedSearch,
                fetchLimit: Self.maxAutocompleteCount
            )

            let groupContacts = combinedResults.compactMap { $0 as? GroupContact }
            let realResults = groupContacts.filter {
                !addedRecipients.map(\.email).contains($0.autocompletableName)
            }

            shouldAddUserProposal = !(realResults.count == 1 && realResults.first?.autocompletableName == textDebounce.text)

            guard shouldAddUserProposal else {
                autocompletion = Array(combinedResults.prefix(10))
                return
            }

            let mergedContact = MergedContact(email: textDebounce.text, local: nil, remote: nil)
            mergedContact.name = textDebounce.text

            autocompletion = combinedResults.prefix(10) + [mergedContact]
        }
    }
}

#Preview {
    AutocompletionView(
        textDebounce: TextDebounce(),
        autocompletion: .constant([]),
        addedRecipients: .constant(PreviewHelper.sampleRecipientsList)
    ) { _ in /* Preview */ }
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
