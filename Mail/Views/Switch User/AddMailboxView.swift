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
    enum FocusedField {
        case mailAddress, hiddenPassword, visiblePassword
    }

    @Environment(\.dismiss) var dismiss

    var completion: (Mailbox?) -> Void

    @State private var newAddress = ""
    @State private var password = ""
    @State private var isSecured = true
    @FocusState private var focusedField: FocusedField?
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
                .focused($focusedField, equals: .mailAddress)
                .textContentType(.emailAddress)
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

            Text(MailResourcesStrings.Localizable.errorAttachAddressInput)
                .textStyle(showError ? .labelError : .labelSecondary)
                .padding(.bottom, 8)

            HStack {
                if isSecured {
                    SecureField(MailResourcesStrings.Localizable.attachAddressPasswordInputHint, text: $password)
                        .focused($focusedField, equals: .hiddenPassword)
                        .textContentType(.password)
                } else {
                    TextField(MailResourcesStrings.Localizable.attachAddressPasswordInputHint, text: $password)
                        .focused($focusedField, equals: .visiblePassword)
                        .textContentType(.password)
                }

                Button {
                    isSecured.toggle()
                    focusedField = isSecured ? .hiddenPassword : .visiblePassword
                } label: {
                    if isSecured {
                        MailResourcesAsset.view.swiftUIImage
                            .foregroundColor(MailResourcesAsset.textSecondaryColor.swiftUIColor)
                    } else {
                        MailResourcesAsset.viewOff.swiftUIImage
                            .foregroundColor(MailResourcesAsset.textSecondaryColor.swiftUIColor)
                    }
                }
            }
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
        .onAppear {
            focusedField = .mailAddress
        }
        .navigationBarTitle(MailResourcesStrings.Localizable.attachAddressTitle, displayMode: .inline)
        .padding(.horizontal, 16)
        .padding(.vertical, 32)
    }

    private func addMailbox() {
        Task {
            do {
                try await AccountManager.instance.addMailbox(mail: newAddress, password: password) { mailbox in
                    @InjectService var matomo: MatomoUtils
                    matomo.track(eventWithCategory: .account, name: "addMailboxConfirm")
                    completion(mailbox)
                }
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
        AddMailboxView { _ in }
    }
}
