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
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

extension VerticalAlignment {
    struct NewMessageCellAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[.firstTextBaseline]
        }
    }

    struct ChevronAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.center]
        }
    }

    static let newMessageCellAlignment = VerticalAlignment(NewMessageCellAlignment.self)
    static let chevronAlignment = VerticalAlignment(ChevronAlignment.self)
}

class TextDebounce: ObservableObject {
    @Published var text = ""
}

struct ComposeMessageCellRecipients: View {
    @StateObject private var textDebounce = TextDebounce()

    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var autocompletion = [any ContactAutocompletable]()

    @Binding var recipients: RealmSwift.List<Recipient>
    @Binding var showRecipientsFields: Bool
    @Binding var autocompletionType: ComposeViewFieldType?

    @FocusState var focusedField: ComposeViewFieldType?

    let type: ComposeViewFieldType
    var areCCAndBCCEmpty = false

    let isRecipientLimitExceeded: Bool

    /// It should be displayed only for the field to if cc and bcc are empty and when autocompletion is not displayed
    private var shouldDisplayChevron: Bool {
        return type == .to && autocompletionType == nil && areCCAndBCCEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            if autocompletionType == nil || autocompletionType == type {
                HStack(alignment: .chevronAlignment, spacing: 0) {
                    HStack(alignment: .newMessageCellAlignment) {
                        Text(type.title)
                            .textStyle(.bodySecondary)
                            .alignmentGuide(.chevronAlignment) { d in
                                d[VerticalAlignment.center]
                            }

                        RecipientField(
                            focusedField: _focusedField,
                            currentText: $textDebounce.text,
                            recipients: $recipients,
                            type: type
                        ) {
                            if let bestMatch = autocompletion.first {
                                addNewRecipient(bestMatch)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if shouldDisplayChevron {
                        ChevronButton(isExpanded: $showRecipientsFields)
                            .alignmentGuide(.chevronAlignment) { d in
                                d[VerticalAlignment.center]
                            }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, IKPadding.composeViewHeaderHorizontal)

                IKDivider()
            }

            if autocompletionType == type {
                AutocompletionView(
                    textDebounce: textDebounce,
                    autocompletion: $autocompletion,
                    addedRecipients: $recipients,
                    addRecipient: addNewRecipient
                )
                .padding(.top, value: .mini)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = type
        }
        .onChange(of: textDebounce.text) { newValue in
            withAnimation {
                if newValue.isEmpty {
                    autocompletionType = nil
                } else {
                    autocompletionType = type
                }
            }
        }
    }

    @MainActor private func addNewRecipient(_ contact: any ContactAutocompletable) {
        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .newMessage, name: "addNewRecipient")

        @InjectService var snackbarPresenter: IKSnackBarPresentable
        if isRecipientLimitExceeded {
            snackbarPresenter.show(message: MailResourcesStrings.Localizable.errorTooManyRecipients)
            return
        }

        do {
            let mergedContacts = extractContacts(contact)
            let validContacts = try recipientCheck(mergedContacts: mergedContacts)
            convertMergedContactsToRecipients(validContacts)
        } catch RecipientError.invalidEmail {
            snackbarPresenter.show(message: MailResourcesStrings.Localizable.addUnknownRecipientInvalidEmail)
        } catch RecipientError.duplicateContact {
            snackbarPresenter.show(message: MailResourcesStrings.Localizable.addUnknownRecipientAlreadyUsed)
        } catch {
            snackbarPresenter.show(message: MailResourcesStrings.Localizable.errorUnknown)
        }
        textDebounce.text = ""
    }

    private func extractContacts(_ contacts: any ContactAutocompletable) -> [MergedContact] {
        var mergedContacts: [MergedContact] = []
        if let mergedContact = contacts as? MergedContact {
            mergedContacts.append(mergedContact)
        } else if let groupContact = contacts as? GroupContact {
            let groupContacts = mailboxManager.contactManager.getContacts(with: groupContact.id)
            mergedContacts.append(contentsOf: groupContacts)
        } else if let addressBookContact = contacts as? AddressBook {
            let addressBookContacts = mailboxManager.contactManager.getContacts(for: addressBookContact.id)
            mergedContacts.append(contentsOf: addressBookContacts)
        }
        return mergedContacts
    }

    private func recipientCheck(mergedContacts: [MergedContact]) throws -> [MergedContact] {
        let contactsWithValidMail = mergedContacts.filter { EmailChecker(email: $0.email).validate() }
        if contactsWithValidMail.isEmpty {
            throw RecipientError.invalidEmail
        }

        let newUniqueContacts = contactsWithValidMail.filter { contact in
            !recipients.contains { $0.email == contact.email }
        }

        if newUniqueContacts.isEmpty {
            throw RecipientError.duplicateContact
        }

        let remainingCapacity = 100 - recipients.count
        if newUniqueContacts.count > remainingCapacity {
            @InjectService var snackbarPresenter: IKSnackBarPresentable
            snackbarPresenter.show(message: MailResourcesStrings.Localizable.errorTooManyRecipients)
        }

        return Array(newUniqueContacts.prefix(max(remainingCapacity, 0)))
    }

    private func convertMergedContactsToRecipients(_ mergedContacts: [MergedContact]) {
        for mergedContact in mergedContacts {
            let newRecipient = Recipient(email: mergedContact.email, name: mergedContact.name)
            withAnimation {
                newRecipient.isAddedByMe = true
                $recipients.append(newRecipient)
            }
        }
    }
}

#Preview {
    ComposeMessageCellRecipients(
        recipients: .constant(PreviewHelper.sampleRecipientsList),
        showRecipientsFields: .constant(false),
        autocompletionType: .constant(nil),
        type: .bcc,
        isRecipientLimitExceeded: false
    )
    .environmentObject(PreviewHelper.sampleMailboxManager)
    .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}
