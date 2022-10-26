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

extension Account: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class AccountListViewModel: ObservableObject {
    @Published var expandedUserId: Int? = AccountManager.instance.currentUserId

    @Published var accounts = [Account: [Mailbox]]()

    private var mailboxObservationToken: NotificationToken?

    init() {
        mailboxObservationToken = MailboxInfosManager.instance.getRealm()
            .objects(Mailbox.self)
            .sorted(by: \.mailboxId)
            .observe(on: DispatchQueue.main) { [weak self] results in
                switch results {
                case let .initial(mailboxes):
                    self?.handleMailboxChanged(Array(mailboxes))
                case let .update(mailboxes, _, _, _):
                    withAnimation {
                        self?.handleMailboxChanged(Array(mailboxes))
                    }
                case .error:
                    break
                }
            }
    }

    private func handleMailboxChanged(_ mailboxes: [Mailbox]) {
        for account in AccountManager.instance.accounts {
            accounts[account] = mailboxes.filter { $0.userId == account.userId }
        }
    }
}

struct AccountListView: View {
    @StateObject private var viewModel = AccountListViewModel()
    @State var isShowingNewAccountView = false

    var body: some View {
        ScrollView {
            VStack {
                ForEach(Array(viewModel.accounts.keys)) { account in
                    if let mailboxes = viewModel.accounts[account] {
                        AccountCellView(account: account,
                                        expandedUserId: $viewModel.expandedUserId,
                                        mailboxes: mailboxes)
                    }
                }
            }
            .padding(8)
        }
        .background(MailResourcesAsset.backgroundColor.swiftUiColor)
        .navigationBarTitle(MailResourcesStrings.Localizable.titleMyAccounts, displayMode: .inline)
        .floatingActionButton(icon: Image(systemName: "plus"), title: MailResourcesStrings.Localizable.buttonAddAccount) {
            isShowingNewAccountView = true
        }
        .sheet(isPresented: $isShowingNewAccountView, onDismiss: {
            AppDelegate.orientationLock = .all
        }, content: {
            OnboardingView(isPresentedModally: true, page: 4, isScrollEnabled: false)
        })
        .task {
            try? await updateUsers()
        }
    }

    private func updateUsers() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for account in AccountManager.instance.accounts {
                group.addTask {
                    _ = try await AccountManager.instance.updateUser(for: account, registerToken: false)
                }
            }
        }
    }
}

struct AccountListView_Previews: PreviewProvider {
    static var previews: some View {
        AccountListView()
    }
}
