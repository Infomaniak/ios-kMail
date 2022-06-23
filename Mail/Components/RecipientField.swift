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
    @State private var currentText = ""
    @State private var autocompletion: [MergedContact] = []
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
                        guard let contact = autocompletion.first else { return }
                        recipients.append(Recipient(email: contact.email, name: contact.name))
                        currentText = ""
                        fieldIsFocused = true
                    }
            }
        }
        .onChange(of: currentText) { _ in
            updateAutocompletion()
        }
    }

    private func updateAutocompletion() {
        let contactManager = AccountManager.instance.currentContactManager
        autocompletion = contactManager?.contacts(matching: currentText) ?? []
        debugPrint("Autocompletion results: \(autocompletion.map { "\($0.name) - \($0.email)" })")
    }
}

struct RecipientField_Previews: PreviewProvider {
    static var previews: some View {
        RecipientField(recipients: .constant([PreviewHelper.sampleRecipient1, PreviewHelper.sampleRecipient2, PreviewHelper.sampleRecipient3]))
    }
}
