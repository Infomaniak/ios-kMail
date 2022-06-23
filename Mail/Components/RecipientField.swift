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
import MailResources
import SwiftUI
import WrappingHStack

struct RecipientChip: View {
    let recipient: Recipient
    let removeButtonTapped: () -> Void

    var body: some View {
        HStack(spacing: 2) {
            Text(recipient.name.isEmpty ? recipient.email : recipient.name)
                .textStyle(.body)
                .padding([.top, .bottom], 6)
                .lineLimit(1)

            Button(action: removeButtonTapped) {
                Image(resource: MailResourcesAsset.cross)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .padding(6)
            }
            .tint(.primary)
        }
        .padding(.leading, 12)
        .padding(.trailing, 6)
        .background(Capsule().fill(Color(MailResourcesAsset.backgroundHeaderColor.color)))
    }
}

struct RecipientField: View {
    @Binding var recipients: [Recipient]
    @Binding var autocompletion: [Recipient]
    @Binding var addRecipientHandler: ((Recipient) -> Void)?

    @State private var currentText = ""
    @FocusState private var fieldIsFocused: Bool

    var body: some View {
        WrappingHStack(0 ... recipients.count, spacing: .constant(8), lineSpacing: 8) { i in
            if i < recipients.count {
                RecipientChip(recipient: recipients[i]) {
                    recipients.remove(at: i)
                }
                .layoutPriority(1)
            } else {
                TextField("", text: $currentText)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .multilineTextAlignment(.leading)
                    .focused($fieldIsFocused)
                    .onSubmit {
                        guard let recipient = autocompletion.first else { return }
                        add(recipient: recipient)
                    }
            }
        }
        .onChange(of: currentText) { _ in
            updateAutocompletion()
            addRecipientHandler = add(recipient:)
        }
    }

    private func updateAutocompletion() {
        let contactManager = AccountManager.instance.currentContactManager
        let contacts = contactManager?.contacts(matching: currentText) ?? []
        autocompletion = contacts.map { Recipient(email: $0.email, name: $0.name) }
        // Append typed email
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", Constants.mailRegex)
        if emailPredicate.evaluate(with: currentText) && !autocompletion.contains(where: { $0.email.caseInsensitiveCompare(currentText) == .orderedSame }) {
            autocompletion.append(Recipient(email: currentText, name: ""))
        }
    }

    private func add(recipient: Recipient) {
        recipients.append(recipient)
        currentText = ""
        fieldIsFocused = true
    }
}

struct RecipientField_Previews: PreviewProvider {
    static var previews: some View {
        RecipientField(recipients: .constant([
            PreviewHelper.sampleRecipient1, PreviewHelper.sampleRecipient2, PreviewHelper.sampleRecipient3
        ]),
        autocompletion: .constant([]),
        addRecipientHandler: .constant { _ in })
    }
}
