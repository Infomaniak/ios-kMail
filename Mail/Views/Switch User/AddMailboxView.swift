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

import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct AddMailboxView: View {
    @Environment(\.dismiss) var dismiss

    @State private var newAddress = ""
    @State private var password = ""
    @State private var showError = false

    private var buttonDisabled: Bool {
        return !Constants.isEmailAddress(newAddress) || password.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(MailResourcesStrings.Localizable.attachAddressDescription)
                .textStyle(.bodySecondary)
                .padding(.bottom, 32)

            TextField(MailResourcesStrings.Localizable.attachAddressInputHint, text: $newAddress)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .padding(12)
                .overlay {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(
                            showError ? MailResourcesAsset.redColor.swiftUIColor : MailResourcesAsset.elementsColor.swiftUIColor,
                            lineWidth: 1
                        )
                }
                .padding(.bottom, 4)

            Text(MailResourcesStrings.Localizable.attachAddressInputHelper)
                .textStyle(showError ? .labelError : .labelSecondary)
                .padding(.bottom, 8)

            SecureField(MailResourcesStrings.Localizable.attachAddressPasswordInputHint, text: $password)
                .textContentType(.password)
                .padding([.vertical, .leading], 12)
                .padding(.trailing, 16)
                .overlay {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(
                            showError ? MailResourcesAsset.redColor.swiftUIColor : MailResourcesAsset.elementsColor.swiftUIColor,
                            lineWidth: 1
                        )
                }
                .padding(.bottom, 4)

            Text(MailResourcesStrings.Localizable.errorInvalidCredentials)
                .textStyle(.labelError)
                .opacity(showError ? 1 : 0)

            Spacer()

            MailButton(label: MailResourcesStrings.Localizable.buttonAttachEmailAddress) {
                addMailbox()
            }
            .disabled(buttonDisabled)
            .mailButtonFullWidth(true)
        }
        .navigationBarTitle(MailResourcesStrings.Localizable.attachAddressTitle, displayMode: .inline)
        .padding(.horizontal, 16)
        .padding(.vertical, 32)
    }

    private func addMailbox() {
        Task {
            do {
                try await AccountManager.instance.addMailbox(mail: newAddress, password: password)
            } catch {
                withAnimation {
                    showError = true
                    password = ""
                }
                await IKSnackBar.showSnackBar(message: error.localizedDescription)
            }
        }
    }
}

struct AddMailboxView_Previews: PreviewProvider {
    static var previews: some View {
        AddMailboxView()
    }
}
