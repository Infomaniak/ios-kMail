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
    @Binding var isPresented: Bool

    @Environment(\.window) private var window

    @State private var avatarImage = MailResourcesAsset.placeholderAvatar.image
    @State private var user: UserProfile! = AccountManager.instance.currentAccount.user

    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                Image(uiImage: avatarImage)
                    .resizable()
                    .frame(width: 110, height: 110)
                    .clipShape(Circle())

                VStack(spacing: 8) {
                    Text(user.email)
                        .textStyle(.header2)

                    NavigationLink {
                        AccountListView()
                    } label: {
                        Text(MailResourcesStrings.buttonAccountSwitch)
                            .textStyle(.button)
                    }
                }

                // TODO: - Show email list
                SeparatorView(withPadding: false, fullWidth: true)
                HStack {
                    Text(MailResourcesStrings.buttonAccountAssociatedEmailAddresses)
                    Spacer()
                    ChevronIcon(style: .right)
                }
                .padding([.leading, .trailing], 14)
                SeparatorView(withPadding: false, fullWidth: true)

                // TODO: - Appareil list

                Button {
                    // TODO: - Delete account
                } label: {
                    Text(MailResourcesStrings.buttonAccountDelete)
                        .textStyle(.button)
                }

                Button {
                    AccountManager.instance.removeTokenAndAccount(token: AccountManager.instance.currentAccount.token)
                    if let nextAccount = AccountManager.instance.accounts.first {
                        (window?.windowScene?.delegate as? SceneDelegate)?.switchAccount(nextAccount)
                    } else {
                        (window?.windowScene?.delegate as? SceneDelegate)?.showLoginView()
                    }
                    AccountManager.instance.saveAccounts()
                } label: {
                    Text(MailResourcesStrings.buttonAccountDisconnect)
                        .textStyle(.button)
                }

                Spacer()
            }
            .navigationBarTitle(MailResourcesStrings.titleMyAccount, displayMode: .inline)
            .backButtonDisplayMode(.minimal)
            .navigationBarItems(leading: Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
            })
            .padding([.top, .bottom], 30)
            .padding([.leading, .trailing], 18)
        }
        .navigationBarAppStyle()
        .onAppear {
            user.getAvatar(size: CGSize(width: 110, height: 110)) { image in
                self.avatarImage = image
            }
        }
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView(isPresented: .constant(true))
    }
}
