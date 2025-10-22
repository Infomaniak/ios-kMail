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

import Foundation
import InAppTwoFactorAuthentication
import InfomaniakCore
import InfomaniakDI
import MailCore
import RealmSwift
import UIKit
import UserNotifications

public struct NotificationTappedPayload {
    public let userId: Int
    public let mailboxId: Int
    public let messageId: String
}

@MainActor
final class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var messageActions: MessageActionHandlable
    @LazyInjectService private var mailboxInfosManager: MailboxInfosManager
    @LazyInjectService private var remoteNotificationRegistrer: RemoteNotificationRegistrable
    @LazyInjectService private var tokenStore: TokenStore

    /// Handles the actions related to mail notifications
    /// - Parameters:
    ///   - identifier: the notification type string identifier
    ///   - content: the notification content
    func handleMailAction(for identifier: String, content: UNNotificationContent) async {
        guard let mailboxId = content.userInfo[NotificationsHelper.UserInfoKeys.mailboxId] as? Int,
              let userId = content.userInfo[NotificationsHelper.UserInfoKeys.userId] as? Int,
              let mailbox = mailboxInfosManager.getMailbox(id: mailboxId, userId: userId),
              let mailboxManager = accountManager.getMailboxManager(for: mailbox),
              let messageUid = content.userInfo[NotificationsHelper.UserInfoKeys.messageUid] as? String,
              !messageUid.isEmpty else {
            return
        }

        let isUserConnected = tokenStore.tokenFor(userId: userId) != nil
        guard isUserConnected else {
            remoteNotificationRegistrer.unregister()
            return
        }

        switch identifier {
        case UNNotificationDefaultActionIdentifier:
            try? await messageActions.handleTapOnNotification(
                messageUid: messageUid,
                mailbox: mailbox,
                mailboxManager: mailboxManager
            )
        case NewMailActionIdentifier.archive:
            try? await messageActions.handleArchiveOnNotification(
                messageUid: messageUid,
                mailboxManager: mailboxManager
            )
        case NewMailActionIdentifier.delete:
            try? await messageActions.handleDeleteOnNotification(
                messageUid: messageUid,
                mailboxManager: mailboxManager
            )
        case NewMailActionIdentifier.reply:
            await messageActions.handleReplyOnNotification(
                messageUid: messageUid,
                mailbox: mailbox,
                mailboxManager: mailboxManager
            )
        default:
            break
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        Task {
            await handleMailAction(for: response.actionIdentifier, content: response.notification.request.content)
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        await handleTwoFactorAuthenticationNotification(notification)
        return []
    }

    func handleTwoFactorAuthenticationNotification(_ notification: UNNotification) async {
        @InjectService var inAppTwoFactorAuthenticationManager: InAppTwoFactorAuthenticationManagerable

        guard let userId = inAppTwoFactorAuthenticationManager.handleRemoteNotification(notification) else {
            return
        }

        guard let account = accountManager.account(for: userId),
              let user = await accountManager.userProfileStore.getUserProfile(id: userId) else {
            return
        }

        let apiFetcher = accountManager.getApiFetcher(for: userId, token: account)

        let session = InAppTwoFactorAuthenticationSession(user: user, apiFetcher: apiFetcher)

        inAppTwoFactorAuthenticationManager.checkConnectionAttempts(using: session)
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        NotificationCenter.default.post(name: .openNotificationSettings, object: nil)
    }
}
