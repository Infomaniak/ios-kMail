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
import MailCore
import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override init() {
        super.init()
        let loginService = Factory(type: InfomaniakLogin.self) { _, _ in
            InfomaniakLogin(clientId: MailApiFetcher.clientId)
        }
        let networkLoginService = Factory(type: InfomaniakNetworkLogin.self) { _, _ in
            InfomaniakNetworkLogin(clientId: MailApiFetcher.clientId)
        }
        let keychainHelper = Factory(type: KeychainHelper.self) { _, _ in
            KeychainHelper(accessGroup: AccountManager.accessGroup)
        }

        SimpleResolver.sharedResolver.store(factory: loginService)
        SimpleResolver.sharedResolver.store(factory: networkLoginService)
        SimpleResolver.sharedResolver.store(factory: keychainHelper)
    }

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        if let bestAttemptContent = bestAttemptContent {
            guard let messageUid = bestAttemptContent.userInfo[NotificationsHelper.UserInfoKeys.messageUid] as? String,
                  let mailboxId = bestAttemptContent.userInfo[NotificationsHelper.UserInfoKeys.mailboxId] as? Int,
                  let userId = bestAttemptContent.userInfo[NotificationsHelper.UserInfoKeys.userId] as? Int,
                  let mailbox = MailboxInfosManager.instance.getMailbox(id: mailboxId, userId: userId),
                  let mailboxManager = AccountManager.instance.getMailboxManager(for: mailbox) else {
                return contentHandler(bestAttemptContent)
            }
            Task {
                guard let fetchedMessage = try await BackgroundFetcher.shared.fetchMessage(uid: messageUid,
                                                                                           in: mailboxManager) else {
                    return contentHandler(bestAttemptContent)
                }
                let generatedNotification = NotificationsHelper.generateNotificationFor(message: fetchedMessage,
                                                                                        mailboxId: mailboxId,
                                                                                        userId: userId)
                generatedNotification.userInfo = bestAttemptContent.userInfo
                contentHandler(generatedNotification)
            }
        }
    }

    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
