/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

struct MailboxesManagementView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject var mailboxManager: MailboxManager
    @EnvironmentObject var navigationDrawerState: NavigationDrawerState

    @LazyInjectService private var accountManager: AccountManager

    @ObservedResults(
        Mailbox.self,
        configuration: {
            @InjectService var mailboxInfosManager: MailboxInfosManager
            return mailboxInfosManager.realmConfiguration
        }(),
        sortDescriptor: SortDescriptor(keyPath: \Mailbox.mailboxId)
    ) private var mailboxes

    private var hasOtherMailboxes: Bool {
        return !mailboxes.where {
            $0.userId == mailboxManager.account.userId && $0.mailboxId != mailboxManager.mailbox.mailboxId
        }.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation {
                    navigationDrawerState.showMailboxes.toggle()
                    matomo.track(eventWithCategory: .menuDrawer, name: "mailboxes", value: navigationDrawerState.showMailboxes)
                }
            } label: {
                HStack(spacing: UIPadding.menuDrawerCellSpacing) {
                    IKIcon(MailResourcesAsset.envelope, size: .large)
                        .foregroundStyle(.tint)

                    Text(mailboxManager.mailbox.email)
                        .textStyle(navigationDrawerState.showMailboxes ? .bodyMediumAccent : .bodyMedium)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if hasOtherMailboxes {
                        ChevronIcon(direction: navigationDrawerState.showMailboxes ? .up : .down)
                    }
                }
                .environment(\.isEnabled, true)
                .padding(UIPadding.menuDrawerCell)
            }
            .disabled(!hasOtherMailboxes)

            if navigationDrawerState.showMailboxes {
                VStack(alignment: .leading) {
                    ForEachMailboxView(
                        userId: mailboxManager.account.userId,
                        excludedMailboxIds: [mailboxManager.mailbox.mailboxId]
                    ) { mailbox in
                        MailboxCell(mailbox: mailbox)
                            .mailboxCellStyle(.menuDrawer)
                            .padding(UIPadding.menuDrawerCell)
                    }
                }
                .task {
                    try? await updateAccount()
                }
            }
        }
        .onChange(of: mailboxManager.mailbox.id) { _ in
            withAnimation {
                navigationDrawerState.showMailboxes = false
            }
        }
    }

    private func updateAccount() async throws {
        guard let account = accountManager.account(for: mailboxManager.mailbox.userId) else { return }
        try await accountManager.updateUser(for: account)
    }
}

#Preview {
    MailboxesManagementView()
        .environmentObject(PreviewHelper.sampleMailboxManager)
        .accentColor(UserDefaults.shared.accentColor.primary.swiftUIColor)
}
