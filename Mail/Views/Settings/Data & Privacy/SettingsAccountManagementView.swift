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
import InfomaniakLogin
import MailCore
import MailCoreUI
import MailResources
import Sentry
import SwiftModalPresentation
import SwiftUI

final class SettingsAccountManagementViewDelegate: DeleteAccountDelegate {
    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var snackbarPresenter: IKSnackBarPresentable

    @MainActor func didCompleteDeleteAccount() {
        Task {
            guard let account = accountManager.getCurrentAccount() else { return }
            accountManager.removeTokenAndAccountFor(userId: account.userId)
            if let nextAccount = accountManager.accounts.first {
                accountManager.switchAccount(newUserId: nextAccount.userId)
            }
            snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackBarAccountDeleted)
        }
    }

    @MainActor func didFailDeleteAccount(error: InfomaniakLoginError) {
        SentrySDK.capture(error: error)
        snackbarPresenter.show(message: "Failed to delete account")
    }
}

struct SettingsAccountManagementView: View {
    @ModalState(wrappedValue: nil, context: ContextKeys.account) private var presentedAccountDeletionToken: ApiToken?
    @State private var delegate = SettingsAccountManagementViewDelegate()

    let user: UserProfile

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: IKPadding.medium) {
                    VStack(alignment: .leading, spacing: IKPadding.micro) {
                        Text(MailResourcesStrings.Localizable.usernameTitle)
                            .textStyle(.header2)
                        Text(user.displayName)
                            .textStyle(.bodySecondary)
                    }
                    .lineLimit(1)

                    VStack(alignment: .leading, spacing: IKPadding.micro) {
                        Text(MailResourcesStrings.Localizable.attachMailboxInputHint)
                            .textStyle(.header2)
                        Text(user.email)
                            .textStyle(.bodySecondary)
                    }
                    .lineLimit(1)
                }
                .padding(value: .medium)

                IKDivider()

                Button {
                    @InjectService var matomo: MatomoUtils
                    @InjectService var tokenStore: TokenStore

                    matomo.track(eventWithCategory: .account, name: Action.deleteAccount.matomoName)
                    presentedAccountDeletionToken = tokenStore.tokenFor(userId: user.id)?.apiToken
                } label: {
                    ActionButtonLabel(action: Action.deleteAccount)
                }
            }

            InformationBlockView(
                icon: MailResourcesAsset.warningFill.swiftUIImage,
                message: MailResourcesStrings.Localizable.deleteAccountWarning,
                iconColor: MailResourcesAsset.orangeColor.swiftUIColor
            )
            .padding(value: .medium)
        }
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .navigationBarTitle(MailResourcesStrings.Localizable.settingsAccountManagementTitle, displayMode: .inline)
        .sheet(item: $presentedAccountDeletionToken) { userToken in
            DeleteAccountView(token: userToken, delegate: delegate)
        }
    }
}

extension ApiToken: @retroactive Identifiable {
    public var id: String {
        return "\(userId)\(accessToken)"
    }
}

#Preview {
    SettingsAccountManagementView(user: PreviewHelper.sampleUser)
}
