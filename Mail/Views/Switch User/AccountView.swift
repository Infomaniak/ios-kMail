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

struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.window) private var window

    @State private var avatarImage = Image(resource: MailResourcesAsset.placeholderAvatar)
    @StateObject private var account = AccountManager.instance.currentAccount!
    @StateObject private var sheet = AccountSheet()
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
                            .textStyle(.header3)

                        NavigationLink {
                            AccountListView()
                        } label: {
                            Text(MailResourcesStrings.Localizable.buttonAccountSwitch)
                                .textStyle(.header5Accent)
                        }
                    }

                    // Email list
                    VStack(alignment: .leading, spacing: 12) {
                        Text(MailResourcesStrings.Localizable.buttonAccountAssociatedEmailAddresses)
                            .textStyle(.calloutSecondary)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)

                        ForEach(mailboxes) { mailbox in
                            Text(mailbox.email)
                                .textStyle(.body)
                                .padding(.horizontal, 24)
                            if mailbox != mailboxes.last {
                                IKDivider()
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)
                }

                // Buttons
                LargeButton(title: MailResourcesStrings.Localizable.buttonAccountDisconnect, action: logout)
                    .padding(.bottom, 24)
                Button {
                    sheet.state = .deleteAccount
                } label: {
                    Text(MailResourcesStrings.Localizable.buttonAccountDelete)
                        .textStyle(.header5Error)
                }
            }
            .navigationBarTitle(MailResourcesStrings.Localizable.titleMyAccount, displayMode: .inline)
            .backButtonDisplayMode(.minimal)
            .navigationBarItems(leading: Button {
                dismiss()
            } label: {
                Label(MailResourcesStrings.Localizable.buttonClose, systemImage: "xmark")
            })
            .padding(.bottom, 48)
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
        .defaultAppStorage(.shared)
    }

    private func logout() {
        AccountManager.instance.removeTokenAndAccount(token: account.token)
        if let nextAccount = AccountManager.instance.accounts.first {
            (window?.windowScene?.delegate as? SceneDelegate)?.switchAccount(nextAccount)
        } else {
            (window?.windowScene?.delegate as? SceneDelegate)?.showLoginView()
        }
        AccountManager.instance.saveAccounts()
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView(mailboxes: [PreviewHelper.sampleMailbox])
    }
}
