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

    let addRecipient: @MainActor (any ContactAutocompletable) -> Void
    let autocompletion: any ContactAutocompletable
    var highlight: String?
    let alreadyAppend: Bool
    let unknownRecipient: Bool
    let title: String
    let subtitle: String

    var contactConfiguration: ContactConfiguration {
        if let groupContact = autocompletion as? GroupContact {
            return .groupContact(group: groupContact)
        } else if let addressBook = autocompletion as? AddressBook {
            return .addressBook(addressbook: addressBook)
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
        unknownRecipient: Bool,
        title: String,
        subtitle: String
    ) {
        self.addRecipient = addRecipient
        self.autocompletion = autocompletion
        self.highlight = highlight
        self.alreadyAppend = alreadyAppend
        self.unknownRecipient = unknownRecipient
        self.title = title
        self.subtitle = subtitle
    }

    init(
        addRecipient: @escaping @MainActor (MergedContact) -> Void,
        autocompletion: MergedContact,
        highlight: String?,
        alreadyAppend: Bool,
        unknownRecipient: Bool
    ) {
        self.addRecipient = { addRecipient($0 as! MergedContact) }
        self.autocompletion = autocompletion
        self.alreadyAppend = alreadyAppend
        self.unknownRecipient = unknownRecipient
        title = autocompletion.name
        subtitle = autocompletion.email
    }

    init(
        addRecipient: @escaping @MainActor (GroupContact) -> Void,
        autocompletion: GroupContact,
        highlight: String?,
        alreadyAppend: Bool,
        unknownRecipient: Bool,
        title: String,
        subtitle: String
    ) {
        self.addRecipient = { addRecipient($0 as! GroupContact) }
        self.autocompletion = autocompletion
        self.alreadyAppend = alreadyAppend
        self.unknownRecipient = unknownRecipient
        self.title = title
        self.subtitle = autocompletion.name
    }

    init(
        addRecipient: @escaping @MainActor (AddressBook) -> Void,
        autocompletion: AddressBook,
        highlight: String?,
        alreadyAppend: Bool,
        unknownRecipient: Bool,
        title: String,
        subtitle: String
    ) {
        self.addRecipient = { addRecipient($0 as! AddressBook) }
        self.autocompletion = autocompletion
        self.highlight = highlight
        self.alreadyAppend = alreadyAppend
        self.unknownRecipient = unknownRecipient
        self.title = title
        self.subtitle = autocompletion.name
    }

    var body: some View {
        HStack(spacing: IKPadding.small) {
            Button {
                addRecipient(autocompletion)
            } label: {
                if unknownRecipient {
                    UnknownRecipientCell(email: autocompletion.autocompletableName)
                } else {
                    RecipientCell(contact: autocompletion,
                                  contactConfiguration: contactConfiguration,
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
    }
}

#Preview {
    AutocompletionCell(
        addRecipient: { _ in /* Preview */ },
        autocompletion: PreviewHelper.sampleMergedContact,
        highlight: "",
        alreadyAppend: false,
        unknownRecipient: false,
        title: "",
        subtitle: ""
    )
    .environmentObject(PreviewHelper.sampleMailboxManager)
}
