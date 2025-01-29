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
import SwiftUI

struct AccountListView: View {
    @LazyInjectService private var orientationManager: OrientationManageable
    @LazyInjectService private var accountManager: AccountManager

    @State private var isShowingNewAccountView = false
    @State private var users: [UserProfile]?

    /// Optional as this view can be displayed from a context without a mailboxManager available
    let mailboxManager: MailboxManager?

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: IKPadding.micro) {
                if let users {
                    ForEach(users) { user in
                        AccountCellView(
                            selectedUserId: .constant(accountManager.currentUserId),
                            mailboxManager: mailboxManager,
                            user: user
                        )
                        .padding(.horizontal, value: .medium)
                    }
                } else {
                    ForEach(accountManager.accounts) { _ in
                        AccountCellPlaceholderView()
                            .padding(.horizontal, value: .medium)
                    }
                }
            }

            IKDivider()
                .padding(.vertical, value: .mini)

            AccountActionsView()
                .padding(.horizontal, value: .mini)
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
            var storedUsers = [UserProfile]()
            for account in accountManager.accounts {
                if let user = await accountManager.userProfileStore.getUserProfile(id: account.userId) {
                    storedUsers.append(user)
                }

                group.addTask {
                    _ = try await accountManager.updateUser(for: account)
                }
            }

            users = storedUsers
        }
    }
}

#Preview {
    AccountListView(mailboxManager: nil)
}
