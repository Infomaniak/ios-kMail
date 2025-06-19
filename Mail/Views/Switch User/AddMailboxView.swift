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

import InfomaniakCore
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct AddMailboxView: View {
    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var snackbarPresenter: SnackBarPresentable

    @Environment(\.currentUser) private var currentUser

    @State private var newAddress = ""
    @State private var password = ""
    @State private var showError = false
    @State private var showInvalidEmailError = false
    @State private var isButtonLoading = false

    private var invalidEmailAddress: Bool {
        return !EmailChecker(email: newAddress).validate()
    }

    private var buttonDisabled: Bool {
        return invalidEmailAddress || password.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(MailResourcesStrings.Localizable.attachMailboxDescription1)
                    .textStyle(.bodySecondary)
                    .padding(.bottom, value: .mini)

                Text(MailResourcesStrings.Localizable.attachMailboxDescription2)
                    .textStyle(.bodySecondary)
                    .padding(.bottom, value: .medium)

                TextField(
                    MailResourcesStrings.Localizable.attachMailboxInputHint,
                    text: $newAddress
                ) { editingChanged in
                    if !editingChanged {
                        showInvalidEmailError = !newAddress.isEmpty && invalidEmailAddress
                    } else {
                        showInvalidEmailError = false
                        showError = false
                    }
                }
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .padding(value: .small)
                .overlay {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(
                            (showError || showInvalidEmailError) ? MailResourcesAsset.redColor
                                .swiftUIColor : MailResourcesAsset
                                .elementsColor.swiftUIColor,
                            lineWidth: 1
                        )
                }
                .padding(.bottom, value: .micro)

                Group {
                    if showInvalidEmailError {
                        Text(MailResourcesStrings.Localizable.errorInvalidEmailAddress)
                    } else {
                        Text(MailResourcesStrings.Localizable.errorInvalidCredentials)
                            .opacity(showError ? 1 : 0)
                    }
                }
                .textStyle(.labelError)
                .padding(.bottom, value: .medium)

                SecureField(MailResourcesStrings.Localizable.attachMailboxPasswordInputHint, text: $password)
                    .textContentType(.password)
                    .padding([.vertical, .leading], value: .small)
                    .padding(.trailing, value: .medium)
                    .overlay {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(
                                showError ? MailResourcesAsset.redColor.swiftUIColor : MailResourcesAsset.elementsColor
                                    .swiftUIColor,
                                lineWidth: 1
                            )
                    }

                Text(MailResourcesStrings.Localizable.errorInvalidCredentials)
                    .textStyle(.labelError)
                    .opacity(showError ? 1 : 0)
            }
            .padding(value: .medium)
        }
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .safeAreaInset(edge: .bottom) {
            Button(MailResourcesStrings.Localizable.buttonAttachMailbox, action: addMailbox)
                .buttonStyle(.ikBorderedProminent)
                .ikButtonLoading(isButtonLoading)
                .ikButtonFullWidth(true)
                .controlSize(.large)
                .disabled(buttonDisabled)
                .padding(.horizontal, value: .large)
                .padding(.bottom, value: .medium)
        }
        .navigationBarTitle(MailResourcesStrings.Localizable.attachMailboxTitle, displayMode: .inline)
    }

    private func addMailbox() {
        Task {
            do {
                isButtonLoading = true
                try await accountManager.addMailbox(for: currentUser.value.id, mail: newAddress, password: password)
                isButtonLoading = false
            } catch let error as MailApiError where error == .apiInvalidCredential {
                withAnimation {
                    showError = true
                    password = ""
                    isButtonLoading = false
                }
            } catch {
                withAnimation {
                    password = ""
                    isButtonLoading = false
                }
                snackbarPresenter.show(message: error.localizedDescription)
            }
        }
    }
}

#Preview {
    AddMailboxView()
        .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}
