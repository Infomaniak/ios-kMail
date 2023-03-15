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
        let window = UIApplication.shared.mainSceneKeyWindow
        AccountManager.instance.removeTokenAndAccount(token: account.token)
        if let nextAccount = AccountManager.instance.accounts.first {
            (window?.windowScene?.delegate as? SceneDelegate)?.switchAccount(nextAccount)
            IKSnackBar.showSnackBar(message: "Account deleted")
        } else {
            (window?.windowScene?.delegate as? SceneDelegate)?.showLoginView()
        }
        AccountManager.instance.saveAccounts()
    }

    @MainActor func didFailDeleteAccount(error: InfomaniakLoginError) {
        SentrySDK.capture(error: error)
        IKSnackBar.showSnackBar(message: "Failed to delete account")
    }
}

class AccountSheet: SheetState<AccountSheet.State> {
    enum State {
        case deleteAccount
    }
}

class AccountAlert: SheetState<AccountAlert.State> {
    enum State {
        case logout
    }
}

struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.window) private var window

    @LazyInjectService private var matomo: MatomoUtils

    @State private var avatarImage = Image(resource: MailResourcesAsset.placeholderAvatar)
    @StateObject private var account = AccountManager.instance.currentAccount
    @StateObject private var sheet = AccountSheet()
    @StateObject private var alert = AccountAlert()
    @State private var delegate = AccountViewDelegate()

    let mailboxes: [Mailbox]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    // Header
                    avatarImage
                        .resizable()
                        .frame(width: 104, height: 104)
                        .clipShape(Circle())
                        .padding(.top, 24)
                        .padding(.bottom, 16)

                    VStack(spacing: 8) {
                        Text(account.user.email)
                            .textStyle(.header2)

                        NavigationLink {
                            AccountListView()
                        } label: {
                            Text(MailResourcesStrings.Localizable.buttonAccountSwitch)
                                .textStyle(.bodyMediumAccent)
                        }
                    }

                    // Email list
                    VStack(alignment: .leading, spacing: 12) {
                        Text(MailResourcesStrings.Localizable.buttonAccountAssociatedEmailAddresses)
                            .textStyle(.bodySmallSecondary)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)

                        ForEach(mailboxes) { mailbox in
                            Text(mailbox.email)
                                .textStyle(.body)
                                .padding(.horizontal, 24)
                                .onTapGesture {
                                    matomo.track(eventWithCategory: .account, name: "selectMailAddress")
                                }
                            if mailbox != mailboxes.last {
                                IKDivider()
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)

                    Spacer()
                }

                // Buttons
                MailButton(label: MailResourcesStrings.Localizable.buttonAccountDisconnect) {
                    matomo.track(eventWithCategory: .account, name: "logOut")
                    alert.state = .logout
                }
                .mailButtonFullWidth(true)
                .padding(.bottom, 24)
                MailButton(label: MailResourcesStrings.Localizable.buttonAccountDelete) {
                    matomo.track(eventWithCategory: .account, name: "deleteAccount")
                    sheet.state = .deleteAccount
                }
                .mailButtonStyle(.destructive)
            }
            .padding(.horizontal, 24)
            .navigationBarTitle(MailResourcesStrings.Localizable.titleMyAccount, displayMode: .inline)
            .backButtonDisplayMode(.minimal)
            .navigationBarItems(leading: Button {
                dismiss()
            } label: {
                Label(MailResourcesStrings.Localizable.buttonClose, systemImage: "xmark")
            })
            .padding(.bottom, 24)
        }
        .task {
            avatarImage = await account.user.avatarImage
        }
        .sheet(isPresented: $sheet.isShowing) {
            switch sheet.state {
            case .deleteAccount:
                DeleteAccountView(account: account, delegate: delegate)
            case .none:
                EmptyView()
            }
        }
        .customAlert(isPresented: $alert.isShowing) {
            switch alert.state {
            case .logout:
                LogoutConfirmationView(account: account)
            case .none:
                EmptyView()
            }
        }
        .defaultAppStorage(.shared)
        .matomoView(view: [MatomoUtils.View.accountView.displayName, "Main"])
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView(mailboxes: [PreviewHelper.sampleMailbox])
    }
}
