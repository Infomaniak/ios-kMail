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

struct AccountListView: View {
    var body: some View {
        ScrollView {
            VStack {
                ForEach(AccountManager.instance.accounts) { account in
                    AccountCellView(account: account)
                }
            }
        }
        .navigationBarTitle(MailResourcesStrings.titleMyAccounts, displayMode: .inline)
        .padding(16)
        .task {
            try? await withThrowingTaskGroup(of: Void.self) { group in
                for account in AccountManager.instance.accounts where account != AccountManager.instance.currentAccount {
                    group.addTask {
                        _ = try await AccountManager.instance.updateUser(for: account, registerToken: false)
                    }
                }
                try await group.waitForAll()
            }
        }
    }
}

struct AccountListView_Previews: PreviewProvider {
    static var previews: some View {
        AccountListView()
    }
}
