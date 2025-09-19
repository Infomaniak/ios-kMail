/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

import InfomaniakCore
import InfomaniakDI
import InfomaniakLogin
import InfomaniakNotifications
import Intents
import MailCore
import MailResources
import RealmSwift
import UserNotifications

final class NotificationService: UNNotificationServiceExtension {
    // periphery:ignore - Making sure the DI is registered at a very early stage of the app launch.
    private let dependencyInjectionHook = NotificationServiceTargetAssembly()

    @InjectService private var accountManager: AccountManager
    @InjectService private var mailboxInfosManager: MailboxInfosManager

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override init() {
        super.init()
        SentryDebug.setUserId(accountManager.currentUserId)
        ModelMigrator().migrateRealmIfNeeded()
    }

    func prepareBaseEmptyMessageNotification() {
        bestAttemptContent?.body = MailResourcesStrings.Localizable.notificationNewEmail
        bestAttemptContent?.sound = .default
    }

    func prepareEmptyMessageNotification(in mailbox: Mailbox) {
        bestAttemptContent?.title = mailbox.email
        if #available(iOSApplicationExtension 16.0, *) {
            bestAttemptContent?.filterCriteria = MailboxInfosManager.getObjectId(
                mailboxId: mailbox.mailboxId,
                userId: mailbox.userId
            )
        }
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
            // Prepare a base notification in case we can't get mailbox
            prepareBaseEmptyMessageNotification()

            let userInfos = bestAttemptContent.userInfo
            let userId = userInfos[NotificationsHelper.UserInfoKeys.userId] as? Int
            // User id can change for each received notification
            SentryDebug.setUserId(userId ?? accountManager.currentUserId)

            guard let mailboxId = userInfos[NotificationsHelper.UserInfoKeys.mailboxId] as? Int,
                  let userId,
                  let mailbox = mailboxInfosManager.getMailbox(id: mailboxId, userId: userId),
                  let mailboxManager = accountManager.getMailboxManager(for: mailbox) else {
                // This should never happen, we received a notification for an unknown mailbox
                logNotificationFailed(userInfo: userInfos, type: .mailboxNotFound)
                accountManager.removeCachedProperties()
                return contentHandler(bestAttemptContent)
            }

            // Prepare a notification in case we can't fetch the message in time / the message doesn't exist anymore
            prepareEmptyMessageNotification(in: mailbox)
            guard let messageUid = userInfos[NotificationsHelper.UserInfoKeys.messageUid] as? String,
                  let fetchedMessage = try? await NotificationsHelper.fetchMessage(uid: messageUid, in: mailboxManager) else {
                logNotificationFailed(userInfo: userInfos, type: .messageNotFound)
                accountManager.removeCachedProperties()
                return contentHandler(bestAttemptContent)
            }

            await NotificationsHelper.generateBaseNotificationFor(
                message: fetchedMessage,
                mailboxId: mailboxId,
                userId: userId,
                incompleteNotification: bestAttemptContent
            )

            await NotificationsHelper.clearAlreadyReadNotifications(shouldWait: true)

            let completeNotification = await NotificationsHelper.generateCompleteNotification(
                fetchedMessage: fetchedMessage,
                mailboxManager: mailboxManager,
                incompleteNotification: bestAttemptContent
            )

            accountManager.removeCachedProperties()
            contentHandler(completeNotification)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        accountManager.removeCachedProperties()
        if let contentHandler, let bestAttemptContent {
            logNotificationFailed(userInfo: bestAttemptContent.userInfo, type: .expired)
            contentHandler(bestAttemptContent)
        }
    }
}
