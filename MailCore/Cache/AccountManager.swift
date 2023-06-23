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

import CocoaLumberjackSwift
import Foundation
import InfomaniakBugTracker
import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import InfomaniakLogin
import InfomaniakNotifications
import Nuke
import RealmSwift
import Sentry
import SwiftUI

public protocol AccountManagerDelegate: AnyObject {
    func currentAccountNeedsAuthentication()
}

public extension InfomaniakNetworkLoginable {
    func apiToken(username: String, applicationPassword: String) async throws -> ApiToken {
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

    func apiToken(using code: String, codeVerifier: String) async throws -> ApiToken {
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

@globalActor actor AccountActor: GlobalActor {
    static let shared = AccountActor()

    public static func run<T>(resultType: T.Type = T.self, body: @AccountActor @Sendable () throws -> T) async rethrows -> T {
        try await body()
    }
}

public class AccountManager: RefreshTokenDelegate, ObservableObject {
    @LazyInjectService var networkLoginService: InfomaniakNetworkLoginable
    @LazyInjectService var keychainHelper: KeychainHelper
    @LazyInjectService var bugTracker: BugTracker
    @LazyInjectService var notificationService: InfomaniakNotifications
    @LazyInjectService var matomo: MatomoUtils

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
    public weak var delegate: AccountManagerDelegate?
    public var currentUserId: Int {
        didSet {
            UserDefaults.shared.currentMailUserId = currentUserId
            setSentryUserId(userId: currentUserId)
            objectWillChange.send()
        }
    }

    public var currentMailboxId: Int {
        didSet {
            UserDefaults.shared.currentMailboxId = currentMailboxId
            objectWillChange.send()
        }
    }

    public var mailboxes: [Mailbox] {
        return MailboxInfosManager.instance.getMailboxes(for: currentUserId)
    }

    public var currentMailboxManager: MailboxManager? {
        if let currentMailboxManager = getMailboxManager(for: currentMailboxId, userId: currentUserId) {
            return currentMailboxManager
        } else if let newCurrentMailbox = mailboxes.first {
            setCurrentMailboxForCurrentAccount(mailbox: newCurrentMailbox)
            return getMailboxManager(for: newCurrentMailbox)
        } else {
            return nil
        }
    }

    public var currentContactManager: ContactManager? {
        if let currentContactManager = getContactManager(for: currentUserId) {
            return currentContactManager
        } else if let newCurrentAccount = accounts.first {
            setCurrentAccount(account: newCurrentAccount)
            return getContactManager(for: currentUserId)
        } else {
            return nil
        }
    }

    public var currentApiFetcher: MailApiFetcher? {
        return apiFetchers[currentUserId]
    }

    private var mailboxManagers = [String: MailboxManager]()
    private var contactManagers = [String: ContactManager]()
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
            tokens = keychainHelper.loadTokens()
        }

        // Also update current account reference to prevent mismatch
        if let account = accounts.first(where: { $0.userId == currentAccount?.userId }) {
            currentAccount = account
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

    public func getContactManager(for userId: Int) -> ContactManager? {
        if let contactManager = contactManagers[String(userId)] {
            return contactManager
        } else if let token = getTokenForUserId(userId) {
            let apiFetcher = getApiFetcher(for: userId, token: token)
            contactManagers[String(userId)] = ContactManager(user: currentAccount.user, apiFetcher: apiFetcher)
            return contactManagers[String(userId)]
        } else {
            return nil
        }
    }

    private func clearMailboxManagers() {
        mailboxManagers.removeAll()
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
        SentrySDK.capture(message: "Failed refreshing token") { scope in
            scope.setContext(
                value: ["User id": token.userId, "Expiration date": token.expirationDate.timeIntervalSince1970],
                key: "Token Infos"
            )
        }
        tokens.removeAll { $0.userId == token.userId }
        keychainHelper.deleteToken(for: token.userId)
        if let account = account(for: token.userId) {
            account.token = nil
            if account.userId == currentUserId {
                delegate?.currentAccountNeedsAuthentication()
                NotificationsHelper.sendDisconnectedNotification()
            }
        }
    }

    public func createAndSetCurrentAccount(code: String, codeVerifier: String) async throws -> Account {
        let token = try await networkLoginService.apiToken(using: code, codeVerifier: codeVerifier)
        return try await createAndSetCurrentAccount(token: token)
    }

    public func createAndSetCurrentAccount(token: ApiToken) async throws -> Account {
        let apiFetcher = MailApiFetcher(token: token, delegate: self)
        let user = try await apiFetcher.userProfile()

        let mailboxesResponse = try await apiFetcher.mailboxes()
        guard !mailboxesResponse.isEmpty else {
            networkLoginService.deleteApiToken(token: token) { error in
                DDLogError("Failed to delete api token: \(error.localizedDescription)")
            }
            throw MailError.noMailbox
        }

        matomo.track(eventWithCategory: .userInfo, name: "nbMailboxes", value: Float(mailboxesResponse.count))

        let newAccount = Account(apiToken: token)
        newAccount.user = user
        addAccount(account: newAccount)
        setCurrentAccount(account: newAccount)

        for mailbox in mailboxesResponse {
            mailbox.permissions = try await apiFetcher.permissions(mailbox: mailbox)
            if mailbox.isLimited {
                mailbox.quotas = try await apiFetcher.quotas(mailbox: mailbox)
            }
        }

        MailboxInfosManager.instance.storeMailboxes(user: user, mailboxes: mailboxesResponse)
        if let mainMailbox = mailboxesResponse.first(where: { $0.isPrimary }) ?? mailboxesResponse.first {
            await notificationService.updateTopicsIfNeeded([mainMailbox.notificationTopicName], userApiFetcher: apiFetcher)
            setCurrentMailboxForCurrentAccount(mailbox: mainMailbox)
        }
        saveAccounts()

        Task {
            try await currentContactManager?.fetchContactsAndAddressBooks()
        }

        return newAccount
    }

    public func updateUser(for account: Account) async throws {
        guard account.isConnected else {
            throw MailError.unknownError
        }

        let apiFetcher = await AccountActor.run {
            getApiFetcher(for: account.userId, token: account.token)
        }
        let user = try await apiFetcher.userProfile(dateFormat: .iso8601)
        account.user = user

        let fetchedMailboxes = try await apiFetcher.mailboxes()
        guard !fetchedMailboxes.isEmpty else {
            removeAccount(toDeleteAccount: account)
            throw MailError.noMailbox
        }
        for mailbox in fetchedMailboxes {
            mailbox.permissions = try await apiFetcher.permissions(mailbox: mailbox)
            if mailbox.isLimited {
                mailbox.quotas = try await apiFetcher.quotas(mailbox: mailbox)
            }
        }

        let mailboxRemovedList = MailboxInfosManager.instance.storeMailboxes(user: user, mailboxes: fetchedMailboxes)
        clearMailboxManagers()
        var switchedMailbox: Mailbox?
        for mailboxRemoved in mailboxRemovedList {
            if currentMailboxManager?.mailbox.mailboxId == mailboxRemoved.mailboxId {
                switchedMailbox = mailboxes.first
                setCurrentMailboxForCurrentAccount(mailbox: switchedMailbox!)
            }
            MailboxManager.deleteUserMailbox(userId: user.id, mailboxId: mailboxRemoved.mailboxId)
        }

        saveAccounts()
    }

    public func loadAccounts() -> [Account] {
        var loadedAccounts = [Account]()
        if let groupDirectoryURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AccountManager.appGroup)?
            .appendingPathComponent("preferences", isDirectory: true) {
            let decoder = JSONDecoder()
            do {
                let data = try Data(contentsOf: groupDirectoryURL.appendingPathComponent("accounts.json"))
                let savedAccounts = try decoder.decode([Account].self, from: data)
                loadedAccounts = savedAccounts
            } catch {
                DDLogError("Error loading accounts \(error)")
            }
        }
        return loadedAccounts
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
                    DDLogError("Error saving accounts \(error)")
                }
            }
        }
    }

    public func switchAccount(newAccount: Account) {
        setCurrentAccount(account: newAccount)
        if let defaultMailbox = (mailboxes.first(where: { $0.isPrimary }) ?? mailboxes.first) {
            setCurrentMailboxForCurrentAccount(mailbox: defaultMailbox)
        }
        saveAccounts()
    }

    public func switchMailbox(newMailbox: Mailbox) {
        setCurrentMailboxForCurrentAccount(mailbox: newMailbox)
        saveAccounts()

        guard let mailboxManager = getMailboxManager(for: newMailbox),
              mailboxManager.getFolder(with: .inbox)?.cursor == nil
        else { return }

        Task { [notificationTopicName = newMailbox.notificationTopicName] in
            let currentSubscription = await notificationService.subscriptionForUser(id: currentUserId)
            guard let currentTopics = currentSubscription?.topics,
                  !currentTopics.contains(notificationTopicName)
            else { return }

            let updatedTopics = currentTopics + [notificationTopicName]
            await notificationService.updateTopicsIfNeeded(updatedTopics, userApiFetcher: mailboxManager.apiFetcher)
        }
    }

    public func addMailbox(mail: String, password: String, completion: (Mailbox?) -> Void) async throws {
        guard let apiFetcher = currentApiFetcher else { return }
        _ = try await apiFetcher.addMailbox(mail: mail, password: password)
        try await updateUser(for: currentAccount)
        completion(mailboxes.first(where: { $0.email == mail }))
    }

    public func setCurrentAccount(account: Account) {
        currentAccount = account
        currentUserId = account.userId
        if !Bundle.main.isExtension {
            matomo.connectUser(userId: "\(currentUserId)")
        }
    }

    private func setSentryUserId(userId: Int) {
        guard userId != 0 else {
            return
        }
        let user = Sentry.User(userId: "\(userId)")
        user.ipAddress = "{{auto}}"
        SentrySDK.setUser(user)
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
        keychainHelper.storeToken(account.token)
        saveAccounts()
    }

    public func removeAccount(toDeleteAccount: Account) {
        if currentAccount == toDeleteAccount {
            currentAccount = nil
            currentMailboxId = 0
            currentUserId = 0
        }
        MailboxManager.deleteUserMailbox(userId: toDeleteAccount.userId)
        ContactManager.deleteUserContacts(userId: toDeleteAccount.userId)
        MailboxInfosManager.instance.removeMailboxesFor(userId: toDeleteAccount.userId)
        mailboxManagers.removeAll()
        contactManagers.removeAll()
        apiFetchers.removeAll()
        accounts.removeAll { $0 == toDeleteAccount }
    }

    public func removeTokenAndAccount(token: ApiToken) {
        tokens.removeAll { $0.userId == token.userId }
        keychainHelper.deleteToken(for: token.userId)
        if let account = account(for: token) {
            removeAccount(toDeleteAccount: account)
        }
        networkLoginService.deleteApiToken(token: token) { error in
            DDLogError("Failed to delete api token: \(error.localizedDescription)")
        }
    }

    public func account(for token: ApiToken) -> Account? {
        return accounts.first { $0.token.userId == token.userId }
    }

    public func account(for userId: Int) -> Account? {
        return accounts.first { $0.userId == userId }
    }

    public func updateToken(newToken: ApiToken, oldToken: ApiToken) {
        keychainHelper.storeToken(newToken)
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

        // Update token for the other contact manager
        for contactManager in contactManagers.values
            where contactManager.user.id != currentUserId && contactManager.apiFetcher.currentToken?.userId == newToken.userId {
            contactManager.apiFetcher.currentToken = newToken
        }
    }

    public func enableBugTrackerIfAvailable() {
        if currentAccount.user?.isStaff == true {
            bugTracker.activateOnScreenshot()
            let apiFetcher = getApiFetcher(for: currentAccount.userId, token: currentAccount.token)
            bugTracker.configure(with: apiFetcher)
        } else {
            bugTracker.stopActivatingOnScreenshot()
        }
    }
}
