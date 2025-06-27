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

import DesignSystem
import InfomaniakCoreSwiftUI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct AutocompletionCell: View {
    @Environment(\.currentUser) private var currentUser
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var subtitle: String

    let addRecipient: @MainActor (any ContactAutocompletable) -> Void
    let autocompletion: any ContactAutocompletable
    let alreadyAppend: Bool
    let unknownRecipient: Bool
    let title: String
    let highlight: String?

    var contactConfiguration: ContactConfiguration {
        if let groupContact = autocompletion as? GroupContact {
            return .groupContact(group: groupContact)
        } else if let addressBook = autocompletion as? AddressBook {
            return .addressBook(addressBook: addressBook)
        } else if let mergedContact = autocompletion as? MergedContact {
            let contact = CommonContact(
                correspondent: mergedContact,
                associatedBimi: nil,
                contextUser: currentUser.value,
                contextMailboxManager: mailboxManager
            )
            return .contact(contact: contact)
        } else {
            return .emptyContact
        }
    }

    init(
        addRecipient: @escaping @MainActor (any ContactAutocompletable) -> Void,
        autocompletion: any ContactAutocompletable,
        highlight: String?,
        alreadyAppend: Bool,
        unknownRecipient: Bool
    ) {
        self.addRecipient = { addRecipient($0) }
        self.autocompletion = autocompletion
        self.highlight = highlight
        self.alreadyAppend = alreadyAppend
        self.unknownRecipient = unknownRecipient

        switch autocompletion {
        case let mergedContact as MergedContact:
            title = mergedContact.name
            _subtitle = State(initialValue: mergedContact.email)
        case let groupContact as GroupContact:
            title = MailResourcesStrings.Localizable.groupContactsTitle(groupContact.name)
            _subtitle = State(initialValue: "")
        case let addressBook as AddressBook:
            title = MailResourcesStrings.Localizable.addressBookTitle(addressBook.name)

            let computedOrganization = addressBook.isDynamicOrganisation ? MailResourcesStrings.Localizable
                .otherOrganisation : addressBook.name

            _subtitle = State(initialValue: MailResourcesStrings.Localizable.organizationName(computedOrganization))
        default:
            title = ""
            _subtitle = State(initialValue: "")
        }
    }

    var body: some View {
        HStack(spacing: IKPadding.small) {
            Button {
                addRecipient(autocompletion)
            } label: {
                if unknownRecipient {
                    UnknownRecipientCell(email: autocompletion.autocompletableName)
                } else {
                    RecipientCell(contactConfiguration: contactConfiguration,
                                  highlight: highlight,
                                  title: title,
                                  subtitle: subtitle)
                }
            }
            .allowsHitTesting(!alreadyAppend || unknownRecipient)
            .opacity(alreadyAppend && !unknownRecipient ? 0.5 : 1)

            if alreadyAppend && !unknownRecipient {
                MailResourcesAsset.checkmarkCircleFill
                    .iconSize(.large)
                    .foregroundStyle(MailResourcesAsset.textTertiaryColor)
            }
        }
        .padding(.horizontal, value: .medium)
        .task {
            guard let groupContact = autocompletion as? GroupContact else { return }

            guard let addressBook = await mailboxManager.contactManager.getFrozenAddressBook(for: groupContact.id) else { return }

            if !addressBook.name.isEmpty {
                subtitle = MailResourcesStrings.Localizable.addressBookTitle(addressBook.name)
            } else if let organization = addressBook.organization {
                subtitle = MailResourcesStrings.Localizable.addressBookTitle(organization)
            }
        }
    }
}

#Preview {
    AutocompletionCell(
        addRecipient: { _ in /* Preview */ },
        autocompletion: PreviewHelper.sampleMergedContact,
        highlight: "",
        alreadyAppend: false,
        unknownRecipient: false
    )
    .environmentObject(PreviewHelper.sampleMailboxManager)
}
