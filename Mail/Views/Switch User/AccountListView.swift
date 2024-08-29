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

final class AccountListViewModel: ObservableObject {
    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var mailboxInfosManager: MailboxInfosManager

    @Published var selectedUserId: Int? = {
        @InjectService var accountManager: AccountManager
        return accountManager.currentUserId
    }()

    @Published var accounts = [InfomaniakCore.UserProfile: [Mailbox]]()

    // periphery:ignore - We need to keep a reference to this to keep receiving events (automatically removed on deinit)
    private var mailboxObservationToken: NotificationToken?

    init() {
        let mailboxes = mailboxInfosManager.fetchResults(ofType: Mailbox.self) { partial in
            partial.sorted(by: \.mailboxId)
        }

        mailboxObservationToken = mailboxes.observe { results in
            switch results {
            case .initial(let mailboxes):
                let frozenMailboxes = mailboxes.freezeIfNeeded()
                Task { @MainActor [weak self] in
                    guard let newAccounts = await self?.handleMailboxChanged(Array(frozenMailboxes)) else { return }

                    self?.accounts = newAccounts
                }
            case .update(let mailboxes, _, _, _):
                let frozenMailboxes = mailboxes.freezeIfNeeded()
                Task { @MainActor [weak self] in
                    guard let newAccounts = await self?.handleMailboxChanged(Array(frozenMailboxes)) else { return }
                    withAnimation {
                        self?.accounts = newAccounts
                    }
                }
            case .error:
                break
            }
        }
    }

    private func handleMailboxChanged(_ mailboxes: [Mailbox]) async -> [InfomaniakCore.UserProfile: [Mailbox]] {
        var newAccounts = [InfomaniakCore.UserProfile: [Mailbox]]()
        for account in accountManager.accounts {
            guard let user = await accountManager.userProfileStore.getUserProfile(id: account.id) else { continue }
            newAccounts[user] = mailboxes.filter { $0.userId == account.userId }
        }

        return newAccounts
    }
}

struct AccountListView: View {
    @StateObject private var viewModel = AccountListViewModel()
    @State var isShowingNewAccountView = false

    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var orientationManager: OrientationManageable
    @LazyInjectService private var accountManager: AccountManager

    /// Optional as this view can be displayed from a context without a mailboxManager available
    let mailboxManager: MailboxManager?

    var body: some View {
        ScrollView {
            VStack(spacing: IKPadding.small) {
                ForEach(Array(viewModel.accounts.keys)) { user in
                    AccountCellView(selectedUserId: $viewModel.selectedUserId, mailboxManager: mailboxManager, user: user)
                }
            }
            .padding(.horizontal, value: .medium)
            .padding(.bottom, 120)
        }
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .navigationBarTitle(MailResourcesStrings.Localizable.titleMyAccounts, displayMode: .inline)
        .floatingActionButton(icon: MailResourcesAsset.plus, title: MailResourcesStrings.Localizable.buttonAddAccount) {
            matomo.track(eventWithCategory: .account, name: "add")
            isShowingNewAccountView = true
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
