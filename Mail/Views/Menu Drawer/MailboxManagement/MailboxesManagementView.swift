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
    @EnvironmentObject var menuSheet: MenuSheet

    @Binding var isExpanded: Bool
    @State private var avatarImage = Image(resource: MailResourcesAsset.placeholderAvatar)

    @ObservedResults(Mailbox.self, configuration: MailboxInfosManager.instance.realmConfiguration, where: { $0.userId == AccountManager.instance.currentUserId }, sortDescriptor: SortDescriptor(keyPath: \Mailbox.mailboxId)) private var mailboxes

    private var otherMailboxes: [Mailbox] {
        return mailboxes.filter { $0.mailboxId != mailboxManager.mailbox.mailboxId }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 0) {
                    avatarImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        .padding(.trailing, 16)
                    Text(mailboxManager.mailbox.email)
                        .foregroundColor(.accentColor)
                        .textStyle(.header3)
                        .lineLimit(1)
                    Spacer()
                    ChevronIcon(style: isExpanded ? .up : .down, color: .primary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 18)
                .background(SelectionBackground(isSelected: true, offsetX: 8, leadingPadding: 0, verticalPadding: 0))
            }

            if isExpanded {
                VStack(alignment: .leading) {
                    ForEach(otherMailboxes) { mailbox in
                        MailboxCell(mailbox: mailbox)
                    }

                    if !otherMailboxes.isEmpty {
                        IKDivider(withPadding: true)
                    }

                    MailboxesManagementButtonView(text: MailResourcesStrings.Localizable.buttonManageAccount) {
                        menuSheet.state = .manageAccount
                    }
                    MailboxesManagementButtonView(text: MailResourcesStrings.Localizable.buttonAccountSwitch) {
                        menuSheet.state = .switchAccount
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
                avatarImage = await user.getAvatar()
            }
        }
    }

    private func updateAccount() async throws {
        guard let account = AccountManager.instance.account(for: mailboxManager.mailbox.userId) else { return }
        try await AccountManager.instance.updateUser(for: account, registerToken: false)
    }
}

struct MailboxesManagementView_Previews: PreviewProvider {
    static var previews: some View {
        MailboxesManagementView(isExpanded: .constant(false))
            .environmentObject(PreviewHelper.sampleMailboxManager)
            .previewLayout(.sizeThatFits)
            .accentColor(UserDefaults.shared.accentColor.primary.swiftUiColor)
    }
}
