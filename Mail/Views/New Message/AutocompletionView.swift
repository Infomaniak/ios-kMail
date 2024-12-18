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

extension Recipient: @retroactive ContactAutocompletable {
    public var contactId: String {
        return id
    }

    public var autocompletableName: String {
        return name
    }

    public func isSameContactAutocompletable(as contactAutoCompletable: any ContactAutocompletable) -> Bool {
        return contactId == contactAutoCompletable.contactId
    }
}

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
                    if let mergedContact = contact as? MergedContact {
                        AutocompletionCell(
                            addRecipient: addRecipient,
                            autocompletion: mergedContact,
                            highlight: textDebounce.text,
                            alreadyAppend: addedRecipients.contains { $0.id == contact.contactId },
                            unknownRecipient: isUserProposal
                        )
                    } else if let groupContact = contact as? GroupContact {
                        AutocompletionCell(
                            addRecipient: addRecipient,
                            autocompletion: groupContact,
                            hightlight: textDebounce.text,
                            alreadyAppend: addedRecipients.contains { $0.id == contact.contactId },
                            unknownRecipient: isUserProposal,
                            title: groupContact.name,
                            subtitle: groupContact.autocompletableName
                        )
                    } else if let addressBookContact = contact as? AddressBook {
                        AutocompletionCell(
                            addRecipient: addRecipient,
                            autocompletion: addressBookContact,
                            hightlight: textDebounce.text,
                            alreadyAppend: addedRecipients.contains { $0.id == contact.contactId },
                            unknownRecipient: isUserProposal,
                            title: addressBookContact.name,
                            subtitle: addressBookContact.autocompletableName
                        )
                    }
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
        let counter = 10

        Task { @MainActor in
            let autocompleteContacts = await Array(mailboxManager.contactManager.frozenContactsAsync(
                matching: trimmedSearch,
                fetchLimit: counter,
                sorted: sortByRemoteAndName
            ))

            let autocompleteGroupContacts = Array(mailboxManager.contactManager.frozenGroupContacts(
                matching: trimmedSearch,
                fetchLimit: counter
            ))

            let autocompleteAddressBookContacts = Array(mailboxManager.contactManager.frozenAddressBookContacts(
                matching: trimmedSearch,
                fetchLimit: counter
            ))

            var combinedResults: [any ContactAutocompletable] = autocompleteContacts + autocompleteGroupContacts +
                autocompleteAddressBookContacts

            let realResults = autocompleteGroupContacts.filter {
                !addedRecipients.map(\.email).contains($0.autocompletableName)
            }

            shouldAddUserProposal = !(realResults.count == 1 && realResults.first?.autocompletableName == textDebounce.text)

            if shouldAddUserProposal {
                combinedResults.append(MergedContact(email: textDebounce.text, local: nil, remote: nil))
            }

            combinedResults.sort { lhs, rhs in
                guard let lhsContact = lhs as? MergedContact,
                      let rhsContact = rhs as? MergedContact else { return false }
                return sortByRemoteAndName(lhs: lhsContact, rhs: rhsContact)
            }

            let result = combinedResults.prefix(10)

            autocompletion = Array(result)
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
