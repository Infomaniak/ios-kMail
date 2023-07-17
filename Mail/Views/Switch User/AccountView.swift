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
import MailCore
import MailResources
import Sentry
import SwiftUI

class AccountViewDelegate: DeleteAccountDelegate {
    @MainActor func didCompleteDeleteAccount() {
        guard let account = AccountManager.instance.currentAccount else { return }
        AccountManager.instance.removeTokenAndAccount(token: account.token)
        if let nextAccount = AccountManager.instance.accounts.first {
            AccountManager.instance.switchAccount(newAccount: nextAccount)
            IKSnackBar.showSnackBar(message: "Account deleted")
        }
        AccountManager.instance.saveAccounts()
    }

    @MainActor func didFailDeleteAccount(error: InfomaniakLoginError) {
        SentrySDK.capture(error: error)
        IKSnackBar.showSnackBar(message: "Failed to delete account")
    }
}

struct AccountView: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var mailboxManager: MailboxManager
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @LazyInjectService private var matomo: MatomoUtils

    @State private var isShowingLogoutAlert = false
    @State private var isShowingDeleteAccount = false
    @State private var delegate = AccountViewDelegate()

    let account: Account

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                AvatarView(displayablePerson: CommonContact(user: account.user), size: 104)
                    .padding(.top, 24)
                    .padding(.bottom, 16)

                VStack(spacing: 0) {
                    Text(account.user.displayName)
                        .textStyle(.header2)
                        .padding(.bottom, 4)

                    Text(account.user.email)
                        .textStyle(.bodySmallSecondary)
                        .padding(.bottom, 16)

                    NavigationLink {
                        AccountListView()
                    } label: {
                        Text(MailResourcesStrings.Localizable.buttonAccountSwitch)
                            .textStyle(.bodyMediumAccent)
                    }
                }

                MailboxListView(currentMailbox: mailboxManager.mailbox)

                Spacer()
            }

            // Buttons
            MailButton(label: MailResourcesStrings.Localizable.buttonAccountDisconnect) {
                matomo.track(eventWithCategory: .account, name: "logOut")
                isShowingLogoutAlert.toggle()
            }
            .mailButtonFullWidth(true)
            .padding(.bottom, 24)
            MailButton(label: MailResourcesStrings.Localizable.buttonAccountDelete) {
                matomo.track(eventWithCategory: .account, name: "deleteAccount")
                isShowingDeleteAccount.toggle()
            }
            .mailButtonStyle(.destructive)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 16)
        .navigationBarTitle(MailResourcesStrings.Localizable.titleMyAccount, displayMode: .inline)
        .backButtonDisplayMode(.minimal)
        .sheet(isPresented: $isShowingDeleteAccount) {
            DeleteAccountView(account: account, delegate: delegate)
        }
        .customAlert(isPresented: $isShowingLogoutAlert) {
            LogoutConfirmationView(account: account)
        }
        .sheetViewStyle()
        .matomoView(view: [MatomoUtils.View.accountView.displayName, "Main"])
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView(account: PreviewHelper.sampleAccount)
    }
}
