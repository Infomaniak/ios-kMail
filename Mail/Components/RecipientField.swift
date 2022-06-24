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
    @FocusState var focusedField: RecipientFieldType?
    let type: RecipientFieldType

    @State private var currentText = ""

    var body: some View {
        VStack {
            if !recipients.isEmpty {
                WrappingHStack(recipients.indices, spacing: .constant(8), lineSpacing: 8) { i in
                    RecipientChip(recipient: recipients[i]) {
                        withAnimation {
                            _ = recipients.remove(at: i)
                        }
                    }
                }
            }
            TextField("", text: $currentText)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .multilineTextAlignment(.leading)
                .focused($focusedField, equals: type)
                .onSubmit {
                    guard let recipient = autocompletion.first else { return }
                    add(recipient: recipient)
                    focusedField = type
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
        withAnimation {
            autocompletion = contacts.map { Recipient(email: $0.email, name: $0.name) }
        }
        // Append typed email
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", Constants.mailRegex)
        if emailPredicate.evaluate(with: currentText) && !autocompletion.contains(where: { $0.email.caseInsensitiveCompare(currentText) == .orderedSame }) {
            autocompletion.append(Recipient(email: currentText, name: ""))
        }
    }

    private func add(recipient: Recipient) {
        withAnimation {
            recipients.append(recipient)
        }
        currentText = ""
    }
}

struct RecipientField_Previews: PreviewProvider {
    static var previews: some View {
        RecipientField(recipients: .constant([
            PreviewHelper.sampleRecipient1, PreviewHelper.sampleRecipient2, PreviewHelper.sampleRecipient3
        ]),
        autocompletion: .constant([]),
        addRecipientHandler: .constant { _ in },
        focusedField: .init(),
        type: .to)
    }
}
