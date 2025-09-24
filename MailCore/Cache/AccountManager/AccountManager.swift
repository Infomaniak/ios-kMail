/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

import DeviceAssociation
import Foundation
import InfomaniakBugTracker
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakDI
import InfomaniakLogin
import InfomaniakNotifications
import MyKSuite
import Nuke
import OSLog
import RealmSwift
import Sentry
import SwiftUI

extension InfomaniakCore.UserProfile: Identifiable {}

public final class AccountManager: RefreshTokenDelegate, ObservableObject {
    @LazyInjectService var deviceManager: DeviceManagerable
    @LazyInjectService var networkLoginService: InfomaniakNetworkLoginable
    @LazyInjectService var tokenStore: TokenStore
    @LazyInjectService var bugTracker: BugTracker
    @LazyInjectService var notificationService: InfomaniakNotifications
    @LazyInjectService var matomo: MatomoUtils
    @LazyInjectService var mailboxInfosManager: MailboxInfosManager
    @LazyInjectService var featureFlagsManager: FeatureFlagsManageable
    @LazyInjectService var myKSuiteStore: MyKSuiteStore

    private static let appIdentifierPrefix = Bundle.main.infoDictionary!["AppIdentifierPrefix"] as! String
    private static let group = "com.infomaniak.mail"

    public static let appGroup = "group." + group
    public static let accessGroup: String = AccountManager.appIdentifierPrefix + AccountManager.group

    @SendableProperty private var currentAccount: ApiToken?

    public var currentUserId: Int {
        didSet {
            UserDefaults.shared.currentMailUserId = currentUserId
            SentryDebug.setUserId(currentUserId)
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
            .sorted(by: { lhs, _ in return lhs.isPrimary })
            .first(where: \.isAvailable) {
            setCurrentMailboxForCurrentAccount(mailbox: newCurrentMailbox)
            return getMailboxManager(for: newCurrentMailbox)
        } else {
            return nil
        }
    }

    public var accounts: [ApiToken] {
        return tokenStore.getAllTokens().values.map { $0.apiToken }
    }

    public var accountIds: [Int] {
        return accounts.map { $0.userId }
    }

    public let userProfileStore = UserProfileStore()
    private let mailboxManagers = SendableDictionary<String, MailboxManager>()
    private let contactManagers = SendableDictionary<String, ContactManager>()
    private let apiFetchers = SendableDictionary<Int, MailApiFetcher>()

    /// Local error handling
    enum ErrorDomain: Error {
        case failedToDeleteAPIToken(wrapping: Error)
    }

    public init() {
        currentMailboxId = UserDefaults.shared.currentMailboxId
        currentUserId = UserDefaults.shared.currentMailUserId

        if let account = account(for: currentUserId) ?? accounts.first {
            setCurrentAccount(account: account)

            switchToFirstValidMailboxManager()
        }
    }

    // MARK: - Mailbox

    public func getCurrentAccount() -> ApiToken? {
        return currentAccount
    }

    public func getCurrentUser() async -> InfomaniakCore.UserProfile? {
        return await userProfileStore.getUserProfile(id: currentUserId)
    }

    public func getMailboxManager(for mailbox: Mailbox) -> MailboxManager? {
        return getMailboxManager(for: mailbox.mailboxId, userId: mailbox.userId)
    }

    public func getMailboxManager(for mailboxId: Int, userId: Int) -> MailboxManager? {
        let objectId = MailboxInfosManager.getObjectId(mailboxId: mailboxId, userId: userId)

        if let mailboxManager = mailboxManagers[objectId] {
            return mailboxManager
        } else if account(for: userId) != nil,
                  let token = tokenStore.tokenFor(userId: userId),
                  let mailbox = mailboxInfosManager.getMailbox(id: mailboxId, userId: userId) {
            let apiFetcher = getApiFetcher(for: userId, token: token)
            let contactManager = getContactManager(for: userId, apiFetcher: apiFetcher)
            mailboxManagers[objectId] = MailboxManager(mailbox: mailbox,
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

    public func getApiFetcher(for userId: Int, token: AssociatedApiToken) -> MailApiFetcher {
        getApiFetcher(for: userId, token: token.apiToken)
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
        SentryDebug.logTokenMigration(newToken: newToken, oldToken: oldToken)
        Task {
            let deviceId = try await deviceManager.getOrCreateCurrentDevice().uid
            tokenStore.addToken(newToken: newToken, associatedDeviceId: deviceId)
        }
    }

    public func didFailRefreshToken(_ token: ApiToken) {
        SentrySDK.capture(message: "Failed refreshing token") { scope in
            scope.setContext(
                value: ["User id": token.userId, "Expiration date": token.expirationDate?.timeIntervalSince1970 ?? "infinite"],
                key: "Token Infos"
            )
        }

        removeTokenAndAccountFor(userId: token.userId)
        Task { @MainActor in
            NotificationsHelper.sendDisconnectedNotification()
        }
    }

    public func createAndSetCurrentAccount(code: String, codeVerifier: String) async throws {
        let token = try await networkLoginService.apiTokenUsing(code: code, codeVerifier: codeVerifier)
        SentryDebug.setUserId(token.userId)

        do {
            let (apiFetcher, mailboxes) = try await createAccount(token: token)
            await setCurrentAccount(token: token, mailboxes: mailboxes, apiFetcher: apiFetcher)
        } catch {
            removeTokenAndAccountFor(userId: token.userId)
            throw error
        }
    }

    public func createAccount(token: ApiToken) async throws -> (ApiFetcher, [Mailbox]) {
        let apiFetcher = MailApiFetcher(token: token, delegate: self)

        attachDeviceToApiToken(token, apiFetcher: apiFetcher)

        let user = try await userProfileStore.updateUserProfile(with: apiFetcher)

        let mailboxesResponse = try await apiFetcher.mailboxes()
        guard !mailboxesResponse.isEmpty else {
            throw MailError.noMailbox
        }

        matomo.track(eventWithCategory: .userInfo, action: .data, name: "nbMailboxes", value: Float(mailboxesResponse.count))

        try await addAccount(token: token)

        async let _ = fetchExtras(
            hasFreeMailbox: mailboxesResponse.contains { $0.isFree },
            apiFetcher: apiFetcher,
            userId: user.id
        )

        await fetchMailboxesMetadata(mailboxes: mailboxesResponse, apiFetcher: apiFetcher)

        await mailboxInfosManager.storeMailboxes(user: user, mailboxes: mailboxesResponse)

        return (apiFetcher, mailboxesResponse)
    }

    public func setCurrentAccount(token: ApiToken, mailboxes: [Mailbox], apiFetcher: ApiFetcher) async {
        let availableMailboxes = mailboxes.filter { $0.isAvailable }
        guard let mainMailbox = (availableMailboxes.first(where: { $0.isPrimary }) ?? availableMailboxes.first)?.freezeIfNeeded()
        else {
            return
        }

        await notificationService.updateTopicsIfNeeded([mainMailbox.notificationTopicName], userApiFetcher: apiFetcher)
        let currentMailboxManager = getMailboxManager(for: mainMailbox)
        try? await currentMailboxManager?.refreshAllFolders()

        setCurrentAccount(account: token)
        setCurrentMailboxForCurrentAccount(mailbox: mainMailbox)
    }

    public func updateUser(for account: ApiToken?) async throws {
        guard let account,
              let associatedToken = tokenStore.tokenFor(userId: account.userId) else {
            SentryDebug.captureNoTokenError(account: account)
            throw MailError.noToken
        }

        let apiFetcher = getApiFetcher(for: account.userId, token: associatedToken.apiToken)

        attachDeviceToApiToken(associatedToken.apiToken, apiFetcher: apiFetcher)

        let user = try await userProfileStore.updateUserProfile(with: apiFetcher)

        let fetchedMailboxes = try await apiFetcher.mailboxes()
        guard !fetchedMailboxes.isEmpty else {
            removeAccountFor(userId: account.userId)
            throw MailError.noMailbox
        }

        async let _ = fetchExtras(
            hasFreeMailbox: fetchedMailboxes.contains { $0.isFree },
            apiFetcher: apiFetcher,
            userId: user.id
        )

        await fetchMailboxesMetadata(mailboxes: fetchedMailboxes, apiFetcher: apiFetcher)

        let mailboxRemovedList = await mailboxInfosManager.storeMailboxes(user: user, mailboxes: fetchedMailboxes)
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
    }

    private func attachDeviceToApiToken(_ token: ApiToken, apiFetcher: ApiFetcher) {
        Task {
            do {
                let device = try await deviceManager.getOrCreateCurrentDevice()
                try await deviceManager.attachDeviceIfNeeded(device, to: token, apiFetcher: apiFetcher)
            } catch {
                SentryDebug.asyncCapture(message: "failedToAttachDeviceError", context: ["error": error], level: .error)
            }
        }
    }

    private func fetchExtras(hasFreeMailbox: Bool, apiFetcher: ApiFetcher, userId: Int) async {
        if hasFreeMailbox {
            Task {
                _ = try? await self.myKSuiteStore.updateMyKSuite(with: apiFetcher, id: userId)
            }
        }
        Task {
            try? await self.featureFlagsManager.fetchFlags()
        }
    }

    private func fetchMailboxesMetadata(mailboxes: [Mailbox], apiFetcher: MailApiFetcher) async {
        await withTaskGroup(of: Void.self) { group in
            for mailbox in mailboxes where mailbox.isAvailable {
                group.addTask {
                    async let permissions = apiFetcher.permissions(mailbox: mailbox)
                    async let externalMailInfo = apiFetcher.externalMailFlag(mailbox: mailbox)
                    async let sendersRestrictions = apiFetcher.sendersRestrictions(mailbox: mailbox)

                    if mailbox.isLimited {
                        async let quotas = apiFetcher.quotas(mailbox: mailbox)
                        mailbox.quotas = try? await quotas
                        mailbox.quotas?.maxStorage = mailbox.maxStorage
                    }

                    mailbox.permissions = try? await permissions
                    mailbox.externalMailInfo = try? await externalMailInfo
                    mailbox.sendersRestrictions = try? await sendersRestrictions
                }
            }

            await group.waitForAll()
        }
    }

    public func switchToFirstValidMailboxManager() {
        // Current mailbox is valid
        if let firstValidMailboxManager = currentMailboxManager, firstValidMailboxManager.mailbox.isAvailable {
            return
        }

        // At least one mailbox is valid
        let mailboxes = mailboxInfosManager.getMailboxes(for: currentUserId)
        if let firstValidMailbox = mailboxes.first(where: { $0.isAvailable && $0.userId == currentUserId }) {
            switchMailbox(newMailbox: firstValidMailbox)
            return
        }

        // No valid mailbox for current user
        currentMailboxId = 0
    }

    public func switchAccount(newUserId: Int) {
        guard let newAccount = accounts.first(where: { $0.userId == newUserId }) else { return }
        setCurrentAccount(account: newAccount)
        let mailboxes = mailboxInfosManager.getMailboxes(for: newUserId)
        if let defaultMailbox = (mailboxes.first(where: \.isPrimary) ?? mailboxes.first) {
            setCurrentMailboxForCurrentAccount(mailbox: defaultMailbox)
        }
    }

    public func switchMailbox(newMailbox: Mailbox) {
        Task {
            self.setCurrentMailboxForCurrentAccount(mailbox: newMailbox, refresh: false)
            SentryDebug.switchMailboxBreadcrumb(mailboxObjectId: newMailbox.objectId)

            guard let mailboxManager = getMailboxManager(for: newMailbox) else {
                return
            }

            guard mailboxManager.getFolder(with: .inbox)?.cursor == nil else {
                return
            }

            let notificationTopicName = newMailbox.notificationTopicName
            let currentSubscription = await notificationService.subscriptionForUser(id: currentUserId)
            guard let currentTopics = currentSubscription?.topics,
                  !currentTopics.contains(notificationTopicName) else {
                return
            }

            let updatedTopics = currentTopics + [notificationTopicName]
            await notificationService.updateTopicsIfNeeded(updatedTopics, userApiFetcher: mailboxManager.apiFetcher)
        }
    }

    public func addMailbox(for userId: Int, mail: String, password: String) async throws {
        guard let token = tokenStore.tokenFor(userId: userId) else {
            return
        }

        let apiFetcher = getApiFetcher(for: userId, token: token)

        try await apiFetcher.addMailbox(mail: mail, password: password)
        try await updateUser(for: currentAccount)

        let mailboxes = mailboxInfosManager.getMailboxes(for: currentUserId)
        guard let addedMailbox = mailboxes.first(where: { $0.email == mail }) else {
            return
        }

        matomo.track(eventWithCategory: .account, name: "addMailboxConfirm")
        switchMailbox(newMailbox: addedMailbox)
    }

    public func updateMailboxPassword(for userId: Int, mailbox: Mailbox, password: String) async throws {
        guard let token = tokenStore.tokenFor(userId: userId) else {
            return
        }

        let apiFetcher = getApiFetcher(for: userId, token: token)

        try await apiFetcher.updateMailboxPassword(mailbox: mailbox, password: password)
        try await updateUser(for: currentAccount)
    }

    public func askMailboxPassword(for userId: Int, mailbox: Mailbox) async throws {
        guard let token = tokenStore.tokenFor(userId: userId) else {
            return
        }

        let apiFetcher = getApiFetcher(for: userId, token: token)

        try await apiFetcher.askMailboxPassword(mailbox: mailbox)
    }

    public func detachMailbox(for userId: Int, mailbox: Mailbox) async throws {
        guard let token = tokenStore.tokenFor(userId: userId) else {
            return
        }

        let apiFetcher = getApiFetcher(for: userId, token: token)

        _ = try await apiFetcher.detachMailbox(mailbox: mailbox)
        try await updateUser(for: currentAccount)
    }

    public func setCurrentAccount(account: ApiToken) {
        currentAccount = account
        currentUserId = account.userId
        if !Bundle.main.isExtension {
            matomo.connectUser(userId: "\(currentUserId)")
        }
    }

    public func setCurrentMailboxForCurrentAccount(mailbox: Mailbox, refresh: Bool = true) {
        currentMailboxId = mailbox.mailboxId
        if refresh {
            _ = getMailboxManager(for: mailbox)
        }
    }

    public func addAccount(token: ApiToken) async throws {
        if accounts.contains(where: { $0.userId == token.userId }) {
            removeAccountFor(userId: token.userId)
        }

        let deviceId = try await deviceManager.getOrCreateCurrentDevice().uid
        tokenStore.addToken(newToken: token, associatedDeviceId: deviceId)
    }

    public func removeAccountFor(userId: Int) {
        if currentAccount?.userId == userId {
            currentAccount = nil
            currentMailboxId = 0
            currentUserId = 0
        }
        MailboxManager.deleteUserMailbox(userId: userId)
        ContactManager.deleteUserContacts(userId: userId)
        mailboxInfosManager.removeMailboxesFor(userId: userId)
        mailboxManagers.removeAll()
        contactManagers.removeAll()
        apiFetchers.removeAll()
        deviceManager.forgetLocalDeviceHash(forUserId: userId)

        Task {
            @InjectService var mainViewStateStore: MainViewStateStore
            await mainViewStateStore.removeMainViewState(for: userId)
        }
    }

    public func removeTokenAndAccountFor(userId: Int) {
        let removedToken = tokenStore.removeTokenFor(userId: userId)
        removeAccountFor(userId: userId)

        guard let removedToken else { return }

        networkLoginService.deleteApiToken(token: removedToken) { result in
            guard case .failure(let error) = result else { return }
            self.logError(.failedToDeleteAPIToken(wrapping: error))
            Logger.general.error("Failed to delete api token: \(error.localizedDescription)")
        }
    }

    public func account(for userId: Int) -> ApiToken? {
        return accounts.first { $0.userId == userId }
    }

    public func enableBugTrackerIfAvailable() async {
        if let currentUser = await userProfileStore.getUserProfile(id: currentUserId),
           let token = tokenStore.tokenFor(userId: currentUser.id),
           currentUser.isStaff == true {
            bugTracker.activateOnScreenshot()
            let apiFetcher = getApiFetcher(for: currentUser.id, token: token)
            bugTracker.configure(with: apiFetcher)
        } else {
            bugTracker.stopActivatingOnScreenshot()
        }
    }

    public func cleanAllRealms() async {
        for account in accounts {
            for mailbox in mailboxInfosManager.getMailboxes(for: account.userId) {
                if let mailboxManager = getMailboxManager(for: mailbox) {
                    mailboxManager.cleanRealm()
                }
            }
        }
    }

    public func removeCachedProperties() {
        mailboxManagers.removeAll()
        contactManagers.removeAll()
        apiFetchers.removeAll()
    }
}
