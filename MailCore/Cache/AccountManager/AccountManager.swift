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

public extension InfomaniakNetworkLoginable {
    func apiToken(username: String, applicationPassword: String) async throws -> ApiToken {
        try await withCheckedThrowingContinuation { continuation in
            getApiToken(username: username, applicationPassword: applicationPassword) { token, error in
                if let token {
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
                if let token {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: error ?? MailError.unknownError)
                }
            }
        }
    }
}

public final class AccountManager: RefreshTokenDelegate, ObservableObject {
    @LazyInjectService var networkLoginService: InfomaniakNetworkLoginable
    @LazyInjectService var tokenStore: TokenStore
    @LazyInjectService var bugTracker: BugTracker
    @LazyInjectService var notificationService: InfomaniakNotifications
    @LazyInjectService var matomo: MatomoUtils
    @LazyInjectService var mailboxInfosManager: MailboxInfosManager
    @LazyInjectService var featureFlagsManager: FeatureFlagsManageable

    private static let appIdentifierPrefix = Bundle.main.infoDictionary!["AppIdentifierPrefix"] as! String
    private static let group = "com.infomaniak.mail"

    private let tag = "ch.infomaniak.token".data(using: .utf8)!
    private var currentAccount: Account?

    public static let appGroup = "group." + group
    public static let accessGroup: String = AccountManager.appIdentifierPrefix + AccountManager.group

    public var accounts = SendableArray<Account>()
    public var tokens = [ApiToken]()
    public let refreshTokenLockedQueue = DispatchQueue(label: "com.infomaniak.mail.refreshtoken")

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

    public var currentMailboxManager: MailboxManager? {
        if let currentMailboxManager = getMailboxManager(for: currentMailboxId, userId: currentUserId) {
            return currentMailboxManager
        } else if let newCurrentMailbox = mailboxInfosManager.getMailboxes(for: currentUserId)
            .first(where: \.isAvailable) {
            setCurrentMailboxForCurrentAccount(mailbox: newCurrentMailbox)
            return getMailboxManager(for: newCurrentMailbox)
        } else {
            return nil
        }
    }

    /// Shorthand for `currentMailboxManager?.contactManager`
    public var currentContactManager: ContactManager? {
        currentMailboxManager?.contactManager
    }

    public var currentApiFetcher: MailApiFetcher? {
        return apiFetchers[currentUserId]
    }

    private let mailboxManagers = SendableDictionary<String, MailboxManager>()
    private let contactManagers = SendableDictionary<String, ContactManager>()
    private let apiFetchers = SendableDictionary<Int, MailApiFetcher>()

    /// Local error handling
    enum ErrorDomain: Error {
        case mailboxManagerMissing
        case mailboxFolderMissing
        case mailboxMissing
        case currentSubscriptionMissing
        case topicMismatch
        case missingAPIFetcher
        case failedToRemoveToken
        case failedToDeleteAPIToken(wrapping: Error)
        case failedToLoadAccounts(wrapping: Error)
        case failedToSaveAccounts(wrapping: Error)
    }

    public init() {
        currentMailboxId = UserDefaults.shared.currentMailboxId
        currentUserId = UserDefaults.shared.currentMailUserId

        forceReload()
    }

    // MARK: - Mailbox

    public func getCurrentAccount() -> Account? {
        return currentAccount
    }

    public func forceReload() {
        currentMailboxId = UserDefaults.shared.currentMailboxId
        currentUserId = UserDefaults.shared.currentMailUserId

        reloadTokensAndAccounts()

        if let account = account(for: currentUserId) ?? accounts.first {
            setCurrentAccount(account: account)

            switchToFirstValidMailboxManager()
        }
    }

    public func reloadTokensAndAccounts() {
        accounts.removeAll()
        let newAccounts = loadAccounts()
        accounts.append(contentsOf: newAccounts)

        // Also update current account reference to prevent mismatch
        if let account = accounts.values.first(where: { $0.userId == currentAccount?.userId }) {
            currentAccount = account
        }

        // remove accounts with no user
        for account in accounts where account.user == nil {
            removeAccount(toDeleteAccount: account)
        }
    }

    public func getMailboxManager(for mailbox: Mailbox) -> MailboxManager? {
        return getMailboxManager(for: mailbox.mailboxId, userId: mailbox.userId)
    }

    public func getMailboxManager(for mailboxId: Int, userId: Int) -> MailboxManager? {
        let objectId = MailboxInfosManager.getObjectId(mailboxId: mailboxId, userId: userId)

        if let mailboxManager = mailboxManagers[objectId] {
            return mailboxManager
        } else if let account = account(for: userId),
                  let token = tokenStore.tokenFor(userId: userId),
                  let mailbox = mailboxInfosManager.getMailbox(id: mailboxId, userId: userId) {
            let apiFetcher = getApiFetcher(for: userId, token: token)
            let contactManager = getContactManager(for: userId, apiFetcher: apiFetcher)
            mailboxManagers[objectId] = MailboxManager(account: account,
                                                       mailbox: mailbox,
                                                       apiFetcher: apiFetcher,
                                                       contactManager: contactManager)
            return mailboxManagers[objectId]
        } else {
            return nil
        }
    }

    public func getContactManager(for userId: Int, apiFetcher: MailApiFetcher) -> ContactManager {
        if let contactManager = contactManagers[String(userId)] {
            return contactManager
        } else {
            let contactManager = ContactManager(userId: userId, apiFetcher: apiFetcher)
            contactManagers[String(userId)] = contactManager
            return contactManager
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

    public func didUpdateToken(newToken: ApiToken, oldToken: ApiToken) {
        tokenStore.addToken(newToken: newToken)
    }

    public func didFailRefreshToken(_ token: ApiToken) {
        SentrySDK.capture(message: "Failed refreshing token") { scope in
            scope.setContext(
                value: ["User id": token.userId, "Expiration date": token.expirationDate.timeIntervalSince1970],
                key: "Token Infos"
            )
        }
        tokenStore.removeTokenFor(userId: token.userId)
        if let account = account(for: token.userId),
           account.userId == currentUserId {
            removeAccount(toDeleteAccount: account)
            NotificationsHelper.sendDisconnectedNotification()
        }
    }

    public func createAndSetCurrentAccount(code: String, codeVerifier: String) async throws -> Account {
        let token = try await networkLoginService.apiToken(using: code, codeVerifier: codeVerifier)
        do {
            return try await createAndSetCurrentAccount(token: token)
        } catch {
            let partiallyCreatedAccount = Account(apiToken: token)
            removeTokenAndAccount(account: partiallyCreatedAccount)
            throw error
        }
    }

    private func createAndSetCurrentAccount(token: ApiToken) async throws -> Account {
        let apiFetcher = MailApiFetcher(token: token, delegate: self)
        let user = try await apiFetcher.userProfile()

        let mailboxesResponse = try await apiFetcher.mailboxes()
        guard !mailboxesResponse.isEmpty else {
            throw MailError.noMailbox
        }

        matomo.track(eventWithCategory: .userInfo, action: .data, name: "nbMailboxes", value: Float(mailboxesResponse.count))

        let newAccount = Account(apiToken: token)
        newAccount.user = user
        addAccount(account: newAccount, token: token)

        try? await featureFlagsManager.fetchFlags()

        for mailbox in mailboxesResponse {
            mailbox.permissions = try await apiFetcher.permissions(mailbox: mailbox)
            if mailbox.isLimited {
                mailbox.quotas = try await apiFetcher.quotas(mailbox: mailbox)
            }
        }

        mailboxInfosManager.storeMailboxes(user: user, mailboxes: mailboxesResponse)
        if let mainMailbox = (mailboxesResponse.first(where: { $0.isPrimary }) ?? mailboxesResponse.first)?.freezeIfNeeded() {
            await notificationService.updateTopicsIfNeeded([mainMailbox.notificationTopicName], userApiFetcher: apiFetcher)
            let currentMailboxManager = getMailboxManager(for: mainMailbox)
            try? await currentMailboxManager?.refreshAllFolders()

            setCurrentAccount(account: newAccount)
            setCurrentMailboxForCurrentAccount(mailbox: mainMailbox)
        }

        saveAccounts()

        Task {
            try await currentMailboxManager?.contactManager.refreshContactsAndAddressBooks()
        }

        return newAccount
    }

    public func updateUser(for account: Account?) async throws {
        guard let account,
              let token = tokenStore.tokenFor(userId: account.userId) else {
            throw MailError.noToken
        }

        let apiFetcher = getApiFetcher(for: account.userId, token: token)
        let user = try await apiFetcher.userProfile(dateFormat: .iso8601)
        account.user = user

        try? await featureFlagsManager.fetchFlags()

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

        let mailboxRemovedList = mailboxInfosManager.storeMailboxes(user: user, mailboxes: fetchedMailboxes)
        mailboxManagers.removeAll()

        var switchedMailbox: Mailbox?
        for mailboxRemoved in mailboxRemovedList {
            if currentMailboxManager?.mailbox.mailboxId == mailboxRemoved.mailboxId {
                switchedMailbox = mailboxInfosManager.getMailboxes(for: account.userId).first
                setCurrentMailboxForCurrentAccount(mailbox: switchedMailbox!)
            }
            MailboxManager.deleteUserMailbox(userId: user.id, mailboxId: mailboxRemoved.mailboxId)
        }

        if currentMailboxManager?.mailbox.isAvailable == false {
            switchToFirstValidMailboxManager()
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
                logError(.failedToLoadAccounts(wrapping: error))
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
            if let data = try? encoder.encode(accounts.values) {
                do {
                    try FileManager.default.createDirectory(atPath: groupDirectoryURL.path, withIntermediateDirectories: true)
                    try data.write(to: groupDirectoryURL.appendingPathComponent("accounts.json"))
                } catch {
                    logError(.failedToSaveAccounts(wrapping: error))
                    DDLogError("Error saving accounts \(error)")
                }
            }
        }
    }

    public func switchToFirstValidMailboxManager() {
        // Current mailbox is valid
        if let firstValidMailboxManager = currentMailboxManager,
           !firstValidMailboxManager.mailbox.isLocked && firstValidMailboxManager.mailbox.isPasswordValid {
            return
        }

        // At least one mailbox is valid
        let mailboxes = mailboxInfosManager.getMailboxes(for: currentUserId)
        if let firstValidMailbox = mailboxes.first(where: { !$0.isLocked && $0.isPasswordValid && $0.userId == currentUserId }) {
            switchMailbox(newMailbox: firstValidMailbox)
            return
        }

        // No valid mailbox for current user
        currentMailboxId = 0
    }

    public func switchAccount(newAccount: Account) {
        setCurrentAccount(account: newAccount)
        let mailboxes = mailboxInfosManager.getMailboxes(for: newAccount.userId)
        if let defaultMailbox = (mailboxes.first(where: \.isPrimary) ?? mailboxes.first) {
            setCurrentMailboxForCurrentAccount(mailbox: defaultMailbox)
        }
        saveAccounts()
    }

    public func switchMailbox(newMailbox: Mailbox) {
        Task {
            self.setCurrentMailboxForCurrentAccount(mailbox: newMailbox, refresh: false)
            self.saveAccounts()
            SentryDebug.switchMailboxBreadcrumb(mailboxObjectId: newMailbox.objectId)

            guard let mailboxManager = getMailboxManager(for: newMailbox) else {
                logError(.mailboxManagerMissing)
                return
            }

            guard mailboxManager.getFolder(with: .inbox)?.cursor == nil else {
                logError(.mailboxFolderMissing)
                return
            }

            let notificationTopicName = newMailbox.notificationTopicName
            let currentSubscription = await notificationService.subscriptionForUser(id: currentUserId)
            guard let currentTopics = currentSubscription?.topics else {
                logError(.currentSubscriptionMissing)
                return
            }

            guard !currentTopics.contains(notificationTopicName) else {
                logError(.topicMismatch)
                return
            }

            let updatedTopics = currentTopics + [notificationTopicName]
            await notificationService.updateTopicsIfNeeded(updatedTopics, userApiFetcher: mailboxManager.apiFetcher)
        }
    }

    public func addMailbox(mail: String, password: String) async throws {
        guard let apiFetcher = currentApiFetcher else {
            logError(.missingAPIFetcher)
            return
        }

        try await apiFetcher.addMailbox(mail: mail, password: password)
        try await updateUser(for: currentAccount)

        let mailboxes = mailboxInfosManager.getMailboxes(for: currentUserId)
        guard let addedMailbox = mailboxes.first(where: { $0.email == mail }) else {
            logError(.mailboxMissing)
            return
        }

        matomo.track(eventWithCategory: .account, name: "addMailboxConfirm")
        switchMailbox(newMailbox: addedMailbox)
    }

    public func updateMailboxPassword(mailbox: Mailbox, password: String) async throws {
        guard let apiFetcher = currentApiFetcher else {
            logError(.missingAPIFetcher)
            return
        }

        try await apiFetcher.updateMailboxPassword(mailbox: mailbox, password: password)
        try await updateUser(for: currentAccount)
    }

    public func askMailboxPassword(mailbox: Mailbox) async throws {
        guard let apiFetcher = currentApiFetcher else {
            logError(.missingAPIFetcher)
            return
        }
        try await apiFetcher.askMailboxPassword(mailbox: mailbox)
    }

    public func detachMailbox(mailbox: Mailbox) async throws {
        guard let apiFetcher = currentApiFetcher else {
            logError(.missingAPIFetcher)
            return
        }
        try await apiFetcher.detachMailbox(mailbox: mailbox)
        try await updateUser(for: currentAccount)
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

    public func setCurrentMailboxForCurrentAccount(mailbox: Mailbox, refresh: Bool = true) {
        currentMailboxId = mailbox.mailboxId
        if refresh {
            _ = getMailboxManager(for: mailbox)
        }
    }

    public func addAccount(account: Account, token: ApiToken) {
        if accounts.values.contains(account) {
            removeAccount(toDeleteAccount: account)
        }
        accounts.append(account)
        tokenStore.addToken(newToken: token)
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
        mailboxInfosManager.removeMailboxesFor(userId: toDeleteAccount.userId)
        mailboxManagers.removeAll()
        contactManagers.removeAll()
        apiFetchers.removeAll()
        accounts.removeAll { $0 == toDeleteAccount }
    }

    public func removeTokenAndAccount(account: Account) {
        let removedToken = tokenStore.removeTokenFor(userId: account.userId) ?? account.token
        removeAccount(toDeleteAccount: account)

        guard let removedToken else {
            logError(.failedToRemoveToken)
            return
        }

        networkLoginService.deleteApiToken(token: removedToken) { error in
            self.logError(.failedToDeleteAPIToken(wrapping: error))
            DDLogError("Failed to delete api token: \(error.localizedDescription)")
        }
    }

    public func account(for token: ApiToken) -> Account? {
        return accounts.values.first { $0.token.userId == token.userId }
    }

    public func account(for userId: Int) -> Account? {
        return accounts.values.first { $0.userId == userId }
    }

    public func enableBugTrackerIfAvailable() {
        if let currentAccount,
           let token = tokenStore.tokenFor(userId: currentAccount.userId),
           currentAccount.user?.isStaff == true {
            bugTracker.activateOnScreenshot()
            let apiFetcher = getApiFetcher(for: currentAccount.userId, token: token)
            bugTracker.configure(with: apiFetcher)
        } else {
            bugTracker.stopActivatingOnScreenshot()
        }
    }

    public func updateConversationSettings() {
        for account in accounts {
            for mailbox in mailboxInfosManager.getMailboxes(for: account.userId) {
                if let mailboxManager = getMailboxManager(for: mailbox) {
                    mailboxManager.cleanRealm()
                }
            }
        }
    }
}
