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

    let mailboxes: [Mailbox]
    let matomo: MatomoUtils

    private var otherMailboxes: [Mailbox] {
        return mailboxes.filter { $0.mailboxId != mailboxManager.mailbox.mailboxId }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Button {
                withAnimation {
                    navigationDrawerState.showMailboxes.toggle()
                    matomo.track(eventWithCategory: .menuDrawer, name: "mailboxes", value: navigationDrawerState.showMailboxes)
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
                        .textStyle(navigationDrawerState.showMailboxes ? .bodyMediumAccent : .bodyMedium)
                        .lineLimit(1)
                    Spacer()
                    if !otherMailboxes.isEmpty {
                        ChevronIcon(style: navigationDrawerState.showMailboxes ? .up : .down, color: .primary)
                    }
                }
                .environment(\.isEnabled, true)
                .padding(.vertical, Constants.menuDrawerVerticalPadding)
                .padding(.horizontal, Constants.menuDrawerHorizontalPadding)
            }
            .disabled(otherMailboxes.isEmpty)

            if navigationDrawerState.showMailboxes {
                VStack(alignment: .leading) {
                    ForEach(otherMailboxes) { mailbox in
                        MailboxCell(mailbox: mailbox, matomo: matomo)
                    }
                }
                .task {
                    try? await updateAccount()
                }
            }

            IKDivider(withPadding: true)
                .padding(.top, 8)
        }
        .padding(.top, 16)
        .task {
            if let user = AccountManager.instance.account(for: mailboxManager.mailbox.userId)?.user {
                avatarImage = await user.avatarImage
            }
        }
        .sheet(isPresented: $isShowingSwitchAccount) {
            SheetView(mailboxManager: mailboxManager) {
                AccountListView()
            }
        }
        .sheet(isPresented: $isShowingManageAccount) {
            AccountView(mailboxes: mailboxes)
        }
    }

    private func updateAccount() async throws {
        guard let account = AccountManager.instance.account(for: mailboxManager.mailbox.userId) else { return }
        try await AccountManager.instance.updateUser(for: account, registerToken: false)
    }
}

struct MailboxesManagementView_Previews: PreviewProvider {
    static var previews: some View {
        MailboxesManagementView(mailboxes: [PreviewHelper.sampleMailbox], matomo: PreviewHelper.sampleMatomo)
            .environmentObject(PreviewHelper.sampleMailboxManager)
            .previewLayout(.sizeThatFits)
            .accentColor(UserDefaults.shared.accentColor.primary.swiftUiColor)
    }
}
