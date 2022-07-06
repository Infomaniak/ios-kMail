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
import RealmSwift
import SwiftUI

struct AccountCellView: View {
    let account: Account
    @Binding var expandedUserId: Int?

    @ObservedResults(Mailbox.self) private var mailboxes

    @Environment(\.window) private var window

    private var isExpanded: Bool {
        return expandedUserId == account.userId
    }

    init(account: Account, expandedUserId: Binding<Int?>) {
        self.account = account
        _mailboxes = .init(Mailbox.self,
                           configuration: MailboxInfosManager.instance.realmConfiguration,
                           where: { $0.userId == account.userId },
                           sortDescriptor: SortDescriptor(keyPath: \Mailbox.mailboxId))
        _expandedUserId = expandedUserId
    }

    var body: some View {
        ZStack {
            if isExpanded {
                RoundedRectangle(cornerRadius: 10)
                    .fill(MailResourcesAsset.backgroundCardSelectedColor.swiftUiColor)
            }

            RoundedRectangle(cornerRadius: 10)
                .stroke(MailResourcesAsset.separatorColor.swiftUiColor, lineWidth: 1)

            VStack {
                Button {
                    withAnimation {
                        expandedUserId = expandedUserId == account.userId ? nil : account.userId
                    }
                } label: {
                    AccountHeaderCell(account: account, isExpanded: Binding(get: {
                        isExpanded
                    }, set: {
                        expandedUserId = $0 ? account.userId : nil
                    }))
                    .padding(.leading, 8)
                    .padding(.trailing, 16)
                }

                if isExpanded {
                    VStack(spacing: 24) {
                        ForEach(mailboxes) { mailbox in
                            Button {
                                (window?.windowScene?.delegate as? SceneDelegate)?.switchAccount(account, mailbox: mailbox)
                            } label: {
                                AccountListMailView(mailbox: mailbox)
                            }
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 4)
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
        }
    }
}

struct AccountHeaderCell: View {
    let account: Account
    @Binding var isExpanded: Bool

    @State private var avatarImage = Image(resource: MailResourcesAsset.placeholderAvatar)

    var body: some View {
        HStack(spacing: 8) {
            avatarImage
                .resizable()
                .frame(width: 38, height: 38)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(account.user.displayName)
                    .textStyle(.header3)
                Text(account.user.email)
                    .textStyle(.callout)
            }

            Spacer()

            ChevronIcon(style: isExpanded ? .up : .down)
        }
        .task {
            avatarImage = await account.user.getAvatar()
        }
    }
}

// struct AccountCellView_Previews: PreviewProvider {
//    static var previews: some View {
//        AccountCellView()
//    }
// }
