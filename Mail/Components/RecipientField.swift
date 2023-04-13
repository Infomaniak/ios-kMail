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
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import RealmSwift
import SwiftUI
import WrappingHStack

struct RecipientField: View {
    @Binding var recipients: RealmSwift.List<Recipient>
    @Binding var autocompletion: [Recipient]
    @Binding var unknownRecipientAutocompletion: String
    @Binding var addRecipientHandler: ((Recipient) -> Void)?
    @FocusState var focusedField: ComposeViewFieldType?
    let type: ComposeViewFieldType

    @State private var currentText = ""
    @State private var keyboardHeight: CGFloat = 0
    @State private var lastChipIsFocused = false

    var body: some View {
        VStack {
            if !recipients.isEmpty {
                WrappingHStack(recipients.indices, spacing: .constant(8), lineSpacing: 8) { i in
                    RecipientChip(recipient: recipients[i], isFocused: i == recipients.count - 1 && lastChipIsFocused) {
                        remove(recipientAt: i)
                    }
                }
                .alignmentGuide(.newMessageCellAlignment) { d in d[.top] + 21 }
            }

            RecipientsTextFieldView(text: $currentText, onSubmit: submitTextField, onBackspace: handleBackspaceTextField)
                .focused($focusedField, equals: type)
        }
        .onChange(of: currentText) { _ in
            lastChipIsFocused = false
            updateAutocompletion()
            addRecipientHandler = add(recipient:)
        }
        .onChange(of: focusedField) { _ in
            lastChipIsFocused = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { output in
            if let userInfo = output.userInfo,
               let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)) { _ in
            keyboardHeight = 0
        }
    }

    @MainActor private func submitTextField() {
        guard let recipient = autocompletion.first else {
            IKSnackBar.showSnackBar(
                message: MailResourcesStrings.Localizable.addUnknownRecipientInvalidEmail,
                anchor: keyboardHeight
            )
            return
        }
        add(recipient: recipient)
        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .newMessage, action: .input, name: "addNewRecipient")
    }

    private func handleBackspaceTextField() {
        if lastChipIsFocused {
            remove(recipientAt: recipients.count - 1)
            lastChipIsFocused = false
        } else {
            lastChipIsFocused = true
        }
    }

    private func updateAutocompletion() {
        let trimmedCurrentText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        let contactManager = AccountManager.instance.currentContactManager
        let autocompleteContacts = contactManager?.contacts(matching: trimmedCurrentText) ?? []
        let autocompleteRecipients = autocompleteContacts.map { Recipient(email: $0.email, name: $0.name) }

        withAnimation {
            autocompletion = autocompleteRecipients.filter { !recipients.map(\.email).contains($0.email) }

            if !trimmedCurrentText.isEmpty && !autocompletion
                .contains(where: { $0.email.caseInsensitiveCompare(trimmedCurrentText) == .orderedSame }) {
                unknownRecipientAutocompletion = trimmedCurrentText
            } else {
                unknownRecipientAutocompletion = ""
            }
        }
    }

    @MainActor private func add(recipient: Recipient) {
        if Constants.emailPredicate.evaluate(with: recipient.email) {
            withAnimation {
                $recipients.append(recipient)
            }
            currentText = ""
        } else {
            IKSnackBar.showSnackBar(
                message: MailResourcesStrings.Localizable.addUnknownRecipientInvalidEmail,
                anchor: keyboardHeight
            )
        }
    }

    private func remove(recipientAt: Int) {
        withAnimation {
            $recipients.remove(at: recipientAt)
        }
    }
}

struct RecipientField_Previews: PreviewProvider {
    static var previews: some View {
        RecipientField(recipients: .constant([
            PreviewHelper.sampleRecipient1, PreviewHelper.sampleRecipient2, PreviewHelper.sampleRecipient3
        ].toRealmList()),
        autocompletion: .constant([]),
        unknownRecipientAutocompletion: .constant(""),
        addRecipientHandler: .constant { _ in /* Preview */ },
        focusedField: .init(),
        type: .to)
    }
}
