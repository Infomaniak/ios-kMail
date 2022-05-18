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

struct AccountCellView: View {
    @State private var avatarImage = MailResourcesAsset.placeholderAvatar.image
    @State var account: Account!

    @State private var showEmailList = false

    var body: some View {
        VStack {
            HStack(spacing: 15) {
                Image(uiImage: avatarImage)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(account.user.displayName)
                        .textStyle(.body)
                    Text(account.user.email)
                        .textStyle(.calloutSecondary)
                }

                Spacer()

                Button {
                    showEmailList.toggle()
                } label: {
                    Image(systemName: "chevron.down")
                }
            }
            .onTapGesture {
                AccountManager.instance.switchAccount(newAccount: account)
                (UIApplication.shared.delegate as? AppDelegate)?.refreshCacheData()
                (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?
                    .setRootViewController(UIHostingController(rootView: SplitView()))
            }
            if showEmailList {
                ForEach(MailboxInfosManager.instance.getMailboxes(for: account.user.id), id: \.mailboxId) { mailbox in
                    AccountListMailView(
                        mailbox: mailbox,
                        isSelected: AccountManager.instance.currentMailboxId == mailbox.mailboxId
                    )
                    .padding()
                    .onTapGesture {
                        AccountManager.instance.switchAccount(newAccount: account)
                        AccountManager.instance.setCurrentMailboxForCurrentAccount(mailbox: mailbox)
                        (UIApplication.shared.delegate as? AppDelegate)?.refreshCacheData()
                        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?
                            .setRootViewController(UIHostingController(rootView: SplitView()))
                    }
                }
                .padding(.leading, 18)
            }
        }
        .padding(.top, 14)
        .padding(.bottom, 11)
        .onAppear {
            account.user.getAvatar { image in
                self.avatarImage = image
            }
        }
    }
}

struct AccountCellView_Previews: PreviewProvider {
    static var previews: some View {
        AccountCellView()
    }
}
