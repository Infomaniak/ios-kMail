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

struct UpdateMailboxPasswordView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var updatedMailboxPassword = ""
    @State private var isShowingError = false
    @State private var isLoading = false

    let mailbox: Mailbox
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("Pour des raisons de sécurité, vous devez saisir le mot de passe de l’adresse mail \(mailbox.email)")

            VStack(alignment: .leading) {
                SecureField("Saisir le mot de passe", text: $updatedMailboxPassword)
                    .textContentType(.password)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .overlay {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(
                                isShowingError ? MailResourcesAsset.redColor.swiftUIColor : MailResourcesAsset.elementsColor
                                    .swiftUIColor,
                                lineWidth: 1
                            )
                    }
                    .disabled(isLoading)
                Text(MailResourcesStrings.Localizable.errorAttachAddressInput)
                    .textStyle(.labelError)
                    .opacity(isShowingError ? 1 : 0)
            }

            MailButton(label: "Enregistrer") {
                updateMailboxPassword()
            }
            .mailButtonFullWidth(true)
            .disabled(isLoading)

            MailButton(label: "Mot de passe oublié ?") {}
                .mailButtonStyle(.link)
                .mailButtonFullWidth(true)

            Spacer()
            MailButton(label: "Détacher l'adresse de votre compte") {
                detachAddress()
            }
            .mailButtonStyle(.link)
            .mailButtonFullWidth(true)
            .disabled(isLoading)
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Saisir le mot de passe")
        .sheetViewStyle()
    }

    func updateMailboxPassword() {
        Task {
            isLoading = true
            do {
                try await AccountManager.instance.updateMailboxPassword(mailbox: mailbox, password: updatedMailboxPassword)
                dismiss()
            } catch {
                isShowingError = true
            }
            isLoading = false
        }
    }

    func detachAddress() {
        Task {
            isLoading = true
            do {
                try await AccountManager.instance.detachMailbox(mailbox: mailbox)
                dismiss()
            } catch {
                isShowingError = true
            }
            isLoading = false
        }
    }
}

struct UpdateMailboxPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        UpdateMailboxPasswordView(mailbox: PreviewHelper.sampleMailbox)
    }
}
