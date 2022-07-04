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

import MailCore
import MailResources
import SwiftUI

class AccountListSheet: SheetState<AccountListSheet.State> {
    enum State {
        case addAccount
    }
}

struct AccountListView: View {
    @State private var expandedUserId: Int? = AccountManager.instance.currentUserId

    @StateObject private var sheet = AccountListSheet()

    var body: some View {
        ScrollView {
            VStack {
                ForEach(AccountManager.instance.accounts) { account in
                    AccountCellView(account: account, expandedUserId: $expandedUserId)
                }
            }
            .padding(8)
        }
        .appShadow(withPadding: true)
        .navigationBarTitle(MailResourcesStrings.Localizable.titleMyAccounts, displayMode: .inline)
        .floatingActionButton(icon: Image(systemName: "plus"), title: MailResourcesStrings.Localizable.buttonAddAccount) {
            sheet.state = .addAccount
        }
        .sheet(isPresented: $sheet.isShowing) {
            switch sheet.state {
            case .addAccount:
                OnboardingView(page: 4)
            case .none:
                EmptyView()
            }
        }
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
            try await group.waitForAll()
        }
    }
}

struct AccountListView_Previews: PreviewProvider {
    static var previews: some View {
        AccountListView()
    }
}
