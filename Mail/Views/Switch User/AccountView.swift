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
import MailCore
import MailResources
import SwiftUI

struct AccountView: View {
    @State private var avatarImage = MailResourcesAsset.placeholderAvatar.image
    @State private var user: UserProfile! = AccountManager.instance.currentAccount.user

    var body: some View {
        VStack(spacing: 25) {
            Image(uiImage: avatarImage)
                .resizable()
                .frame(width: 110, height: 110)
                .clipShape(Circle())

            VStack(spacing: 8) {
                Text(user.email)
                    .textStyle(.header2Normal)

                NavigationLink {
                    AccountListView()
                } label: {
                    Text(MailResourcesStrings.changeAccount)
                        .textStyle(.button)
                }
            }

            // TODO: - Show email list
            SeparatorView(withPadding: false, fullWidth: true)
            HStack {
                Text(MailResourcesStrings.emailAddressesAssociatedWithThisAccount)
                Spacer()
                Image(systemName: "chevron.right")
                    .frame(width: 12, height: 12)
            }
            .padding([.leading, .trailing], 14)
            SeparatorView(withPadding: false, fullWidth: true)

            // TODO: - Appareil list

            Button {
                // TODO: - Delete account
            } label: {
                Text(MailResourcesStrings.deleteAccount)
                    .textStyle(.button)
            }

            Button {
                AccountManager.instance.removeTokenAndAccount(token: AccountManager.instance.currentAccount.token)
                if let nextAccount = AccountManager.instance.accounts.first {
                    AccountManager.instance.switchAccount(newAccount: nextAccount)
                    (UIApplication.shared.delegate as? AppDelegate)?.refreshCacheData()
                    (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.setRootViewController(UIHostingController(rootView: SplitView()))
                } else {
                    (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.setRootViewController(LoginViewController.instantiate())
                }
                AccountManager.instance.saveAccounts()
            } label: {
                Text(MailResourcesStrings.disconnectAccount)
                    .textStyle(.button)
            }

            Spacer()
        }
        .padding([.top, .bottom], 30)
        .padding([.leading, .trailing], 18)
        .onAppear {
            user.getAvatar(size: CGSize(width: 110, height: 110)) { image in
                self.avatarImage = image
            }
        }
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView()
    }
}
