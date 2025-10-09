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
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftModalPresentation
import SwiftUI

struct UpdateMailboxPasswordView: View {
    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var snackbarPresenter: SnackBarPresentable

    @Environment(\.currentUser) private var currentUser

    @EnvironmentObject private var navigationState: RootViewState

    @State private var updatedMailboxPassword = ""
    @State private var isShowingError = false
    @State private var isLoading = false
    @State private var snackBarAwareModifier = SnackBarAwareModifier(inset: 0)

    private var disableButton: Bool {
        return isLoading || showPasswordLengthWarning
    }

    private var showPasswordLengthWarning: Bool {
        return updatedMailboxPassword.count < 5 || updatedMailboxPassword.count > 80
    }

    let mailbox: Mailbox
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: IKPadding.huge) {
                VStack(alignment: .leading, spacing: IKPadding.mini) {
                    Text(MailResourcesStrings.Localizable.enterPasswordDescription1)
                        .textStyle(.bodySecondary)
                    Text(MailResourcesStrings.Localizable.enterPasswordDescription2(mailbox.email))
                        .textStyle(.bodySecondary)
                }

                VStack(alignment: .leading) {
                    SecureField(MailResourcesStrings.Localizable.enterPasswordTitle, text: $updatedMailboxPassword)
                        .textContentType(.password)
                        .padding(.vertical, value: .small)
                        .padding(.horizontal, value: .medium)
                        .overlay {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(
                                    isShowingError ? MailResourcesAsset.redColor.swiftUIColor : MailResourcesAsset.elementsColor
                                        .swiftUIColor,
                                    lineWidth: 1
                                )
                        }
                        .disabled(isLoading)

                    if isShowingError {
                        Text(MailResourcesStrings.Localizable.errorInvalidMailboxPassword)
                            .textStyle(.labelError)
                    } else if showPasswordLengthWarning {
                        Text(MailResourcesStrings.Localizable.errorMailboxPasswordLength)
                            .textStyle(.labelSecondary)
                    }
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: IKPadding.mini) {
                Button(MailResourcesStrings.Localizable.buttonConfirm) {
                    matomo.track(eventWithCategory: .invalidPasswordMailbox, name: "updatePassword")
                    updateMailboxPassword()
                }
                .buttonStyle(.ikBorderedProminent)
                .disabled(disableButton)
                .ikButtonLoading(isLoading)

                Button(MailResourcesStrings.Localizable.buttonRequestPassword) {
                    matomo.track(eventWithCategory: .invalidPasswordMailbox, name: "requestPassword")
                    askMailboxPassword()
                }
                .buttonStyle(.ikBorderless)
            }
            .controlSize(.large)
            .ikButtonFullWidth(true)
            .padding(.horizontal, value: .large)
            .padding(.bottom, value: .medium)
        }
        .modifier(snackBarAwareModifier)
        .overlay {
            ViewGeometry(key: BottomSafeAreaKey.self, property: \.safeAreaInsets.bottom)
        }
        .onPreferenceChange(BottomSafeAreaKey.self) { value in
            snackBarAwareModifier.inset = value
        }
        .onChange(of: updatedMailboxPassword) { newValue in
            if !newValue.isEmpty {
                isShowingError = false
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(MailResourcesStrings.Localizable.enterPasswordTitle)
        .sheetViewStyle()
        .matomoView(view: ["UpdateMailboxPasswordView"])
    }

    func updateMailboxPassword() {
        Task {
            isLoading = true
            do {
                try await accountManager.updateMailboxPassword(for: currentUser.value.id,
                                                               mailbox: mailbox,
                                                               password: updatedMailboxPassword)
                await navigationState.transitionToMainViewIfPossible(targetAccount: nil, targetMailbox: mailbox)
            } catch let error as MailApiError where error == .apiInvalidPassword {
                withAnimation {
                    isShowingError = true
                    updatedMailboxPassword = ""
                }
            } catch {
                withAnimation {
                    updatedMailboxPassword = ""
                }
                snackbarPresenter.show(message: error.localizedDescription)
            }
            isLoading = false
        }
    }

    func askMailboxPassword() {
        Task {
            await tryOrDisplayError {
                try await accountManager.askMailboxPassword(for: currentUser.value.id, mailbox: mailbox)
                snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarMailboxPasswordRequested)
            }
        }
    }
}

#Preview {
    UpdateMailboxPasswordView(mailbox: PreviewHelper.sampleMailbox)
        .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}
