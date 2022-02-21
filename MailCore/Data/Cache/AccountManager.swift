//
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
import InfomaniakCore
import InfomaniakLogin

public protocol AccountManagerDelegate: AnyObject {
    func currentAccountNeedsAuthentication()
}

public extension InfomaniakLogin {
    static func apiToken(username: String, applicationPassword: String) async throws -> ApiToken {
        try await withCheckedThrowingContinuation { continuation in
            getApiToken(username: username, applicationPassword: applicationPassword) { token, error in
                if let token = token {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: error ?? MailError.unknownError)
                }
            }
        }
    }

    static func apiToken(using code: String, codeVerifier: String) async throws -> ApiToken {
        try await withCheckedThrowingContinuation { continuation in
            getApiTokenUsing(code: code, codeVerifier: codeVerifier) { token, error in
                if let token = token {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: error ?? MailError.unknownError)
                }
            }
        }
    }
}

public class AccountManager: RefreshTokenDelegate {
    private static let appIdentifierPrefix = Bundle.main.infoDictionary!["AppIdentifierPrefix"] as! String
    private static let group = "com.infomaniak.mail"
    public static let appGroup = "group." + group
    public static let accessGroup: String = AccountManager.appIdentifierPrefix + AccountManager.group
    public static var instance = AccountManager()
    private let tag = "ch.infomaniak.token".data(using: .utf8)!
    public var currentAccount: Account!
    public var accounts = [Account]()
    public var tokens = [ApiToken]()
    public let refreshTokenLockedQueue = DispatchQueue(label: "com.infomaniak.mail.refreshtoken")
    private let keychainQueue = DispatchQueue(label: "com.infomaniak.mail.keychain")
    public weak var delegate: AccountManagerDelegate?
    public var currentUserId: Int {
        didSet {
            UserDefaults.shared.currentMailUserId = currentUserId
        }
    }

    public var currentMailboxId: Int {
        didSet {
            UserDefaults.shared.currentMailboxId = currentMailboxId
        }
    }

    public var mailboxes: [Mailbox] {
        return MailboxInfosManager.instance.getMailboxes(for: currentUserId)
    }

    public var currentMailboxManager: MailboxManager? {
        print(mailboxes)
        if let currentMailboxManager = getMailboxManager(for: currentMailboxId, userId: currentUserId) {
            return currentMailboxManager
        } else if let newCurrentMailbox = mailboxes.first {
            setCurrentMailboxForCurrentAccount(mailbox: newCurrentMailbox)
            return getMailboxManager(for: newCurrentMailbox)
        } else {
            return nil
        }
    }

    private var mailboxManagers = [String: MailboxManager]()
    private var apiFetchers = [Int: MailApiFetcher]()

    private init() {
        currentMailboxId = UserDefaults.shared.currentMailboxId
        currentUserId = UserDefaults.shared.currentMailUserId

        forceReload()
    }

    public func forceReload() {
        currentMailboxId = UserDefaults.shared.currentMailboxId
        currentUserId = UserDefaults.shared.currentMailUserId

        reloadTokensAndAccounts()

        if let account = account(for: currentUserId) ?? accounts.first {
            setCurrentAccount(account: account)

            if let currentMailbox = MailboxInfosManager.instance
                .getMailbox(id: currentMailboxId, userId: currentUserId) ?? mailboxes.first {
                setCurrentMailboxForCurrentAccount(mailbox: currentMailbox)
            }
        }
    }

    public func reloadTokensAndAccounts() {
        accounts = loadAccounts()
        if !accounts.isEmpty {
            tokens = KeychainHelper.loadTokens()
        }

        // remove accounts with no user
        for account in accounts where account.user == nil {
            removeAccount(toDeleteAccount: account)
        }

        for token in tokens {
            if let account = account(for: token.userId) {
                account.token = token
            } else {
                // remove token with no account
                removeTokenAndAccount(token: token)
            }
        }
    }

    public func getMailboxManager(for mailbox: Mailbox) -> MailboxManager? {
        return getMailboxManager(for: mailbox.mailboxId, userId: mailbox.userId)
    }

    public func getMailboxManager(for mailboxId: Int, userId: Int) -> MailboxManager? {
        let objectId = MailboxInfosManager.getObjectId(mailboxId: mailboxId, userId: userId)

        if let mailboxManager = mailboxManagers[objectId] {
            return mailboxManager
        } else if let token = getTokenForUserId(userId),
                  let mailbox = MailboxInfosManager.instance.getMailbox(id: mailboxId, userId: userId) {
            let apiFetcher = getApiFetcher(for: userId, token: token)
            mailboxManagers[objectId] = MailboxManager(mailbox: mailbox, apiFetcher: apiFetcher)
            return mailboxManagers[objectId]
        } else {
            return nil
        }
    }

    public func getApiFetcher(for userId: Int, token: ApiToken) -> MailApiFetcher {
        if let apiFetcher = apiFetchers[userId] {
            return apiFetcher
        } else {
            let apiFetcher = MailApiFetcher(token: token, delegate: self)
            apiFetchers[userId] = apiFetcher
            return apiFetcher
        }
    }

    public func getTokenForUserId(_ id: Int) -> ApiToken? {
        return account(for: id)?.token
    }

    public func didUpdateToken(newToken: ApiToken, oldToken: ApiToken) {
        updateToken(newToken: newToken, oldToken: oldToken)
    }

    public func didFailRefreshToken(_ token: ApiToken) {
        tokens.removeAll { $0.userId == token.userId }
        KeychainHelper.deleteToken(for: token.userId)
        if let account = account(for: token.userId) {
            account.token = nil
            if account.userId == currentUserId {
                delegate?.currentAccountNeedsAuthentication()
                NotificationsHelper.sendDisconnectedNotification()
            }
        }
    }

    public func createAndSetCurrentAccount(code: String, codeVerifier: String) async throws -> Account {
        let token = try await InfomaniakLogin.apiToken(using: code, codeVerifier: codeVerifier)
        return try await createAndSetCurrentAccount(token: token)
    }

    public func createAndSetCurrentAccount(token: ApiToken) async throws -> Account {
        let newAccount = Account(apiToken: token)
        addAccount(account: newAccount)
        setCurrentAccount(account: newAccount)

        let apiFetcher = ApiFetcher(token: token, delegate: self)
        let user = try await apiFetcher.userProfile()
        newAccount.user = user

        // add get mailboxes
        let mailApiFetcher = MailApiFetcher(token: token, delegate: self)
        let mailboxes = try await mailApiFetcher.mailboxes()
        guard !mailboxes.isEmpty else {
            removeAccount(toDeleteAccount: newAccount)
            throw MailError.noMailbox
        }
        MailboxInfosManager.instance.storeMailboxes(user: user, mailboxes: mailboxes)
        let mainMailbox = mailboxes.first!
        setCurrentMailboxForCurrentAccount(mailbox: mainMailbox)
        saveAccounts()

        return newAccount
    }

    public func loadAccounts() -> [Account] {
        var accounts = [Account]()
        if let groupDirectoryURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AccountManager.appGroup)?
            .appendingPathComponent("preferences", isDirectory: true) {
            let decoder = JSONDecoder()
            do {
                let data = try Data(contentsOf: groupDirectoryURL.appendingPathComponent("accounts.json"))
                let savedAccounts = try decoder.decode([Account].self, from: data)
                accounts = savedAccounts
            } catch {
                // Handle error
            }
        }
        return accounts
    }

    public func saveAccounts() {
        if let groupDirectoryURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AccountManager.appGroup)?
            .appendingPathComponent("preferences/", isDirectory: true) {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(accounts) {
                do {
                    try FileManager.default.createDirectory(atPath: groupDirectoryURL.path, withIntermediateDirectories: true)
                    try data.write(to: groupDirectoryURL.appendingPathComponent("accounts.json"))
                } catch {
                    // Handle error
                }
            }
        }
    }

    public func switchAccount(newAccount: Account) {
        setCurrentAccount(account: newAccount)
        setCurrentMailboxForCurrentAccount(mailbox: mailboxes.first!)
        saveAccounts()
    }

    public func setCurrentAccount(account: Account) {
        currentAccount = account
        currentUserId = account.userId
    }

    public func setCurrentMailboxForCurrentAccount(mailbox: Mailbox) {
        currentMailboxId = mailbox.mailboxId
        _ = getMailboxManager(for: mailbox)
    }

    public func addAccount(account: Account) {
        if accounts.contains(account) {
            removeAccount(toDeleteAccount: account)
        }
        accounts.append(account)
        KeychainHelper.storeToken(account.token)
        saveAccounts()
    }

    public func removeAccount(toDeleteAccount: Account) {
        if currentAccount == toDeleteAccount {
            currentAccount = nil
            currentMailboxId = 0
        }
        accounts.removeAll { account -> Bool in
            account == toDeleteAccount
        }
    }

    public func removeTokenAndAccount(token: ApiToken) {
        tokens.removeAll { $0.userId == token.userId }
        KeychainHelper.deleteToken(for: token.userId)
        if let account = account(for: token) {
            removeAccount(toDeleteAccount: account)
        }
    }

    public func account(for token: ApiToken) -> Account? {
        return accounts.first { $0.token.userId == token.userId }
    }

    public func account(for userId: Int) -> Account? {
        return accounts.first { $0.userId == userId }
    }

    public func updateToken(newToken: ApiToken, oldToken: ApiToken) {
        KeychainHelper.storeToken(newToken)
        for account in accounts where oldToken.userId == account.userId {
            account.token = newToken
        }
        tokens.removeAll { $0.userId == oldToken.userId }
        tokens.append(newToken)

        // Update token for the other mailbox manager
        for mailboxManager in mailboxManagers.values
            where mailboxManager.mailbox != currentMailboxManager?.mailbox && mailboxManager.apiFetcher.currentToken?
            .userId == newToken.userId {
            mailboxManager.apiFetcher.currentToken = newToken
        }
    }
}
