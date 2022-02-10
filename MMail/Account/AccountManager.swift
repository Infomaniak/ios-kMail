//
//  AccountManager.swift
//  mail
//
//  Created by Ambroise Decouttere on 08/02/2022.
//

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

