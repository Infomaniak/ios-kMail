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
import InfomaniakLogin
import Lottie
import MailCore
import MailResources
import Sentry
import SwiftUI

final class AccountViewDelegate: DeleteAccountDelegate {
    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var snackbarPresenter: SnackBarPresentable

    @MainActor func didCompleteDeleteAccount() {
        Task {
            guard let account = accountManager.getCurrentAccount() else { return }
            accountManager.removeTokenAndAccount(account: account)
            if let nextAccount = accountManager.accounts.first {
                accountManager.switchAccount(newAccount: nextAccount)
            }
            snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackBarAccountDeleted)
            accountManager.saveAccounts()
        }
    }

    @MainActor func didFailDeleteAccount(error: InfomaniakLoginError) {
        SentrySDK.capture(error: error)
        snackbarPresenter.show(message: "Failed to delete account")
    }
}

struct AccountView: View {
    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var tokenStore: TokenStore

    private static let avatarViewSize: CGFloat = 104

    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var isShowingLogoutAlert = false
    @State private var presentedAccountDeletionToken: ApiToken?
    @State private var delegate = AccountViewDelegate()
    @State private var isLottieAnimationVisible = false

    let account: Account

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                AvatarView(mailboxManager: mailboxManager,
                           displayablePerson: CommonContact(user: account.user),
                           size: AccountView.avatarViewSize)
                    .padding(.bottom, value: .regular)
                    .padding(.top, value: .medium)
                    .background {
                        LottieView(configuration: LottieConfiguration(id: 1, filename: "illu_easter_egg_halloween"),
                                   isVisible: $isLottieAnimationVisible)
                            .offset(y: AccountView.avatarViewSize)
                            .allowsHitTesting(false)
                    }
                    .zIndex(1)

                VStack(spacing: 0) {
                    Text(account.user.displayName)
                        .textStyle(.header2)
                        .padding(.bottom, value: .verySmall)

                    Text(account.user.email)
                        .textStyle(.bodySmallSecondary)
                        .padding(.bottom, value: .regular)

                    NavigationLink {
                        AccountListView(mailboxManager: mailboxManager)
                    } label: {
                        Text(MailResourcesStrings.Localizable.buttonAccountSwitch)
                            .textStyle(.bodyMediumAccent)
                    }
                }
                .zIndex(0)
                .padding(.horizontal, value: .regular)

                MailboxListView(currentMailbox: mailboxManager.mailbox)

                Spacer()
            }

            VStack(spacing: UIPadding.medium) {
                MailButton(label: MailResourcesStrings.Localizable.buttonAccountDisconnect) {
                    matomo.track(eventWithCategory: .account, name: "logOut")
                    isShowingLogoutAlert.toggle()
                }
                .mailButtonFullWidth(true)

                MailButton(label: MailResourcesStrings.Localizable.buttonAccountDelete) {
                    matomo.track(eventWithCategory: .account, name: "deleteAccount")
                    presentedAccountDeletionToken = tokenStore.tokenFor(userId: account.userId)
                }
                .mailButtonStyle(.destructive)
            }
            .padding(.horizontal, value: .medium)
            .padding(.bottom, value: .regular)
        }
        .onAppear {
            isLottieAnimationVisible = true
        }
        .onDisappear {
            isLottieAnimationVisible = false
        }
        .navigationBarTitle(MailResourcesStrings.Localizable.titleMyAccount, displayMode: .inline)
        .backButtonDisplayMode(.minimal)
        .sheet(item: $presentedAccountDeletionToken) { userToken in
            DeleteAccountView(token: userToken, delegate: delegate)
        }
        .customAlert(isPresented: $isShowingLogoutAlert) {
            LogoutConfirmationView(account: account)
        }
        .sheetViewStyle()
        .matomoView(view: [MatomoUtils.View.accountView.displayName, "Main"])
    }
}

extension ApiToken: Identifiable {
    public var id: String {
        return "\(userId)\(accessToken)"
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView(account: PreviewHelper.sampleAccount)
    }
}
