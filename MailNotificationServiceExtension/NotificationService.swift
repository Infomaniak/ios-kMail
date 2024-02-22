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
import Intents
import MailCore
import MailResources
import RealmSwift
import UserNotifications

final class NotificationService: UNNotificationServiceExtension {
    /// Making sure the DI is registered at a very early stage of the app launch.
    private let dependencyInjectionHook = NotificationServiceTargetAssembly()

    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var mailboxInfosManager: MailboxInfosManager

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override init() {
        super.init()
        ModelMigrator().migrateRealmIfNeeded()
    }

    func fetchMessage(uid: String, in mailboxManager: MailboxManager) async throws -> Message? {
        guard let inboxFolder = mailboxManager.getFolder(with: .inbox),
              inboxFolder.cursor != nil else {
            // We do nothing if we don't have an initial cursor
            return nil
        }
        await mailboxManager.refreshFolderContent(inboxFolder.freezeIfNeeded())

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
            let userInfos = bestAttemptContent.userInfo
            guard let mailboxId = userInfos[NotificationsHelper.UserInfoKeys.mailboxId] as? Int,
                  let userId = userInfos[NotificationsHelper.UserInfoKeys.userId] as? Int,
                  let mailbox = mailboxInfosManager.getMailbox(id: mailboxId, userId: userId),
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

            let baseNotification = await NotificationsHelper.generateBaseNotificationFor(
                message: fetchedMessage,
                mailboxId: mailboxId,
                userId: userId,
                incompleteNotification: bestAttemptContent
            )

            await NotificationsHelper.clearAlreadyReadNotifications(shouldWait: true)

            if let fromRecipient = fetchedMessage.from.first,
               let communicationNotification = await NotificationsHelper.generateCommunicationNotificationFor(
                   message: fetchedMessage,
                   fromRecipient: fromRecipient,
                   mailboxManager: mailboxManager,
                   incompleteNotification: bestAttemptContent
               ) {
                contentHandler(communicationNotification)
            } else {
                let normalNotification = await NotificationsHelper.generateNotificationFor(
                    message: fetchedMessage,
                    incompleteNotification: bestAttemptContent
                )
                contentHandler(normalNotification)
            }
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler, let bestAttemptContent {
            logNotificationFailed(userInfo: bestAttemptContent.userInfo, type: .expired)
            contentHandler(bestAttemptContent)
        }
    }
}
