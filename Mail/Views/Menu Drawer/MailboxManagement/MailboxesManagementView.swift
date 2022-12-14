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

struct MailboxesManagementView: View {
    @EnvironmentObject var mailboxManager: MailboxManager
    @EnvironmentObject var navigationDrawerState: NavigationDrawerState

    @State private var avatarImage = Image(resource: MailResourcesAsset.placeholderAvatar)
    @State private var isShowingManageAccount = false
    @State private var isShowingSwitchAccount = false

    var mailboxes: [Mailbox]

    private var otherMailboxes: [Mailbox] {
        return mailboxes.filter { $0.mailboxId != mailboxManager.mailbox.mailboxId }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Button {
                withAnimation {
                    navigationDrawerState.showMailboxes.toggle()
                }
            } label: {
                HStack(spacing: 0) {
                    Image(resource: MailResourcesAsset.envelope)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.accentColor)
                        .padding(.trailing, 16)
                    Text(mailboxManager.mailbox.email)
                        .textStyle(.header5Accent)
                        .lineLimit(1)
                    Spacer()
                    ChevronIcon(style: navigationDrawerState.showMailboxes ? .up : .down, color: .primary)
                }
                .padding(.vertical, Constants.menuDrawerVerticalPadding)
                .padding(.horizontal, Constants.menuDrawerHorizontalPadding)
                .background(SelectionBackground(isSelected: true, offsetX: 8, leadingPadding: 0, verticalPadding: 0))
            }

            if navigationDrawerState.showMailboxes {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(otherMailboxes) { mailbox in
                        MailboxCell(mailbox: mailbox)
                    }

                    if !otherMailboxes.isEmpty {
                        IKDivider(withPadding: true)
                    }

                    MailboxesManagementButtonView(icon: MailResourcesAsset.userSetting, text: MailResourcesStrings.Localizable.buttonManageAccount) {
                        isShowingManageAccount.toggle()
                    }
                    MailboxesManagementButtonView(icon: MailResourcesAsset.userSwap, text: MailResourcesStrings.Localizable.buttonAccountSwitch) {
                        isShowingSwitchAccount.toggle()
                    }
                }
                .task {
                    try? await updateAccount()
                }
            }
        }
        .padding(.top, 16)
        .task {
            if let user = AccountManager.instance.account(for: mailboxManager.mailbox.userId)?.user {
                avatarImage = await user.avatarImage
            }
        }
        .sheet(isPresented: $isShowingSwitchAccount) {
            SheetView {
                AccountListView()
            }
        }
        .sheet(isPresented: $isShowingManageAccount) {
            AccountView()
        }
    }

    private func updateAccount() async throws {
        guard let account = AccountManager.instance.account(for: mailboxManager.mailbox.userId) else { return }
        try await AccountManager.instance.updateUser(for: account, registerToken: false)
    }
}

struct MailboxesManagementView_Previews: PreviewProvider {
    static var previews: some View {
        MailboxesManagementView(mailboxes: [PreviewHelper.sampleMailbox])
            .environmentObject(PreviewHelper.sampleMailboxManager)
            .previewLayout(.sizeThatFits)
            .accentColor(UserDefaults.shared.accentColor.primary.swiftUiColor)
    }
}
