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
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

struct AccountListView: View {
    @State private var isShowingNewAccountView = false

    @LazyInjectService private var orientationManager: OrientationManageable
    @LazyInjectService private var accountManager: AccountManager

    /// Optional as this view can be displayed from a context without a mailboxManager available
    let mailboxManager: MailboxManager?

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: IKPadding.extraSmall) {
                ForEach(accountManager.accounts.values) { account in
                    AccountCellView(
                        selectedUserId: .constant(accountManager.currentUserId),
                        mailboxManager: mailboxManager,
                        account: account
                    )
                    .padding(.horizontal, value: .medium)
                }
            }

            IKDivider()
                .padding(.vertical, value: .small)

            AccountActionsView()
                .padding(.horizontal, value: .small)
        }
        .fullScreenCover(isPresented: $isShowingNewAccountView, onDismiss: {
            orientationManager.setOrientationLock(.all)
        }, content: {
            SingleOnboardingView()
        })
        .task {
            try? await updateUsers()
        }
        .matomoView(view: [MatomoUtils.View.accountView.displayName, "AccountListView"])
        .accessibilityLabel(MailResourcesStrings.Localizable.buttonAddAccount)
    }

    private func updateUsers() async throws {
        await withThrowingTaskGroup(of: Void.self) { group in
            for account in accountManager.accounts {
                group.addTask {
                    _ = try await accountManager.updateUser(for: account)
                }
            }
        }
    }
}

#Preview {
    AccountListView(mailboxManager: nil)
}
