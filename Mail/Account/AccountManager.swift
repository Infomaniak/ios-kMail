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

import Foundation
import InfomaniakLogin

public class AccountManager {
    public static var instance = AccountManager()

    public var currentAccount: Account!
//    public var contactStore = ContactStore()
//    public var userStore = UserStore()
//    public var signature: Signature?
//    public var trashId: String?

    public var isLoggedIn: Bool {
        return AccountManager.instance.currentAccount?.token != nil
    }

    private init() {
        reloadTokensAndAccounts()
    }

    public func createAndSetCurrentAccount(token: ApiToken) {
        let newAccount = Account(apiToken: token)
        currentAccount = newAccount

        KeychainHelper.storeToken(token)
    }

    public func reloadTokensAndAccounts() {
        if let token = KeychainHelper.loadTokens().first {
            createAndSetCurrentAccount(token: token)
        }
    }

    public func deleteTokenAndAccount() {
        guard currentAccount != nil else { return }
        KeychainHelper.deleteToken(for: currentAccount.userId)
        currentAccount = nil
    }

//    public func loadInfoForAccount() async {
//        await withTaskGroup(of: Void.self) { group in
//            group.addTask {
//                await self.userStore.fetchUser()
//            }
//            group.addTask {
//                await self.contactStore.fetchContactsAndAddressBooks()
//            }
//        }
//    }
}
