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
import InfomaniakDI
import InfomaniakLogin
import InfomaniakNotifications
import MailCore
import MailResources
import RealmSwift
import UserNotifications

final class NotificationService: UNNotificationServiceExtension {
    /// Making sure the DI is registered at a very early stage of the app launch.
    private let dependencyInjectionHook = EarlyDIHook()

    @LazyInjectService private var accountManager: AccountManager

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override init() {
        super.init()
        Logging.initLogging()
        let networkLoginService = Factory(type: InfomaniakNetworkLoginable.self) { _, _ in
            InfomaniakNetworkLogin(clientId: MailApiFetcher.clientId)
        }
        let loginService = Factory(type: InfomaniakLoginable.self) { _, _ in
            InfomaniakLogin(clientId: MailApiFetcher.clientId)
        }
        let keychainHelper = Factory(type: KeychainHelper.self) { _, _ in
            KeychainHelper(accessGroup: AccountManager.accessGroup)
        }
        let notificationService = Factory(type: InfomaniakNotifications.self) { _, _ in
            InfomaniakNotifications(appGroup: AccountManager.appGroup)
        }

        SimpleResolver.sharedResolver.store(factory: networkLoginService)
        SimpleResolver.sharedResolver.store(factory: loginService)
        SimpleResolver.sharedResolver.store(factory: keychainHelper)
        SimpleResolver.sharedResolver.store(factory: notificationService)
    }

    func fetchMessage(uid: String, in mailboxManager: MailboxManager) async throws -> Message? {
        guard let inboxFolder = mailboxManager.getFolder(with: .inbox),
              inboxFolder.cursor != nil else {
            // We do nothing if we don't have an initial cursor
            return nil
        }
        await mailboxManager.refresh(folder: inboxFolder.freezeIfNeeded())

        @ThreadSafe var message = mailboxManager.getRealm().object(ofType: Message.self, forPrimaryKey: uid)

        if let message,
           !message.fullyDownloaded {
            try await mailboxManager.message(message: message)
        }

        message?.realm?.refresh()
        return message?.freezeIfNeeded()
    }

    func prepareEmptyMessageNotification(in mailbox: Mailbox) {
        bestAttemptContent?.title = mailbox.email
        bestAttemptContent?.body = MailResourcesStrings.Localizable.notificationNewEmail
        bestAttemptContent?.sound = .default
        bestAttemptContent?.userInfo = [NotificationsHelper.UserInfoKeys.userId: mailbox.userId,
                                        NotificationsHelper.UserInfoKeys.mailboxId: mailbox.mailboxId]
    }

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        guard let bestAttemptContent else { return }

        Task {
            let userInfos = bestAttemptContent.userInfo
            guard let mailboxId = userInfos[NotificationsHelper.UserInfoKeys.mailboxId] as? Int,
                  let userId = userInfos[NotificationsHelper.UserInfoKeys.userId] as? Int,
                  let mailbox = MailboxInfosManager.instance.getMailbox(id: mailboxId, userId: userId),
                  let mailboxManager = accountManager.getMailboxManager(for: mailbox) else {
                // This should never happen, we received a notification for an unknown mailbox
                logNotificationFailed(userInfo: userInfos, type: .mailboxNotFound)
                return contentHandler(bestAttemptContent)
            }

            // Prepare a notification in case we can't fetch the message in time / the message doesn't exist anymore
            prepareEmptyMessageNotification(in: mailbox)
            guard let messageUid = userInfos[NotificationsHelper.UserInfoKeys.messageUid] as? String,
                  let fetchedMessage = try? await fetchMessage(uid: messageUid, in: mailboxManager) else {
                logNotificationFailed(userInfo: userInfos, type: .messageNotFound)
                return contentHandler(bestAttemptContent)
            }

            let completeNotification = await NotificationsHelper.generateNotificationFor(message: fetchedMessage,
                                                                                         mailboxId: mailboxId,
                                                                                         userId: userId)
            contentHandler(completeNotification)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler, let bestAttemptContent {
            logNotificationFailed(userInfo: bestAttemptContent.userInfo, type: .expired)
            contentHandler(bestAttemptContent)
        }
    }
}
