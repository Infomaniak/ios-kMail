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

import DesignSystem
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftModalPresentation
import SwiftUI

struct MailboxesManagementView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var navigationDrawerState: NavigationDrawerState

    @Environment(\.currentUser) private var currentUser

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
            $0.userId == currentUser.value.id && $0.mailboxId != mailboxManager.mailbox.mailboxId
        }.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation {
                    navigationDrawerState.showMailboxes.toggle()
                    @InjectService var matomo: MatomoUtils
                    matomo.track(eventWithCategory: .menuDrawer, name: "mailboxes", value: navigationDrawerState.showMailboxes)
                }
            } label: {
                HStack(spacing: IKPadding.menuDrawerCellSpacing) {
                    MailResourcesAsset.envelope
                        .iconSize(.large)
                        .foregroundStyle(.tint)

                    Text(mailboxManager.mailbox.emailIdn)
                        .textStyle(navigationDrawerState.showMailboxes ? .bodyMediumAccent : .bodyMedium)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if hasOtherMailboxes {
                        ChevronIcon(direction: navigationDrawerState.showMailboxes ? .up : .down)
                    }
                }
                .environment(\.isEnabled, true)
                .padding(IKPadding.menuDrawerCell)
            }
            .disabled(!hasOtherMailboxes)

            if navigationDrawerState.showMailboxes {
                VStack(alignment: .leading) {
                    ForEachMailboxView(
                        userId: currentUser.value.id,
                        excludedMailboxIds: [mailboxManager.mailbox.mailboxId]
                    ) { mailbox in
                        MailboxCell(mailbox: mailbox)
                            .mailboxCellStyle(.menuDrawer)
                            .padding(IKPadding.menuDrawerCell)
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
        @InjectService var accountManager: AccountManager
        guard let account = accountManager.account(for: mailboxManager.mailbox.userId) else { return }
        try await accountManager.updateUser(for: account)
    }
}

#Preview {
    MailboxesManagementView()
        .environmentObject(PreviewHelper.sampleMailboxManager)
        .accentColor(UserDefaults.shared.accentColor.primary.swiftUIColor)
        .environmentObject(NavigationDrawerState())
        .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}
