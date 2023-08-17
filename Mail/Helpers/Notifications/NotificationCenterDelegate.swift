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
import InfomaniakDI
import MailCore
import RealmSwift
import UIKit
import UserNotifications

public struct NotificationTappedPayload {
    public let messageId: String
}

@MainActor
final class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    @LazyInjectService private var accountManager: AccountManager

    let messageActions = MessageActionHandler()

    /// Handles the actions related to mail notifications
    /// - Parameters:
    ///   - identifier: the notification type string identifier
    ///   - content: the notification content
    /// - Returns: True if handled, false otherwise
    @discardableResult
    internal func handleMailAction(for identifier: String, content: UNNotificationContent) async -> Bool {
        // precond for mail actions
        guard let mailboxId = content.userInfo[NotificationsHelper.UserInfoKeys.mailboxId] as? Int,
              let userId = content.userInfo[NotificationsHelper.UserInfoKeys.userId] as? Int,
              let mailbox = MailboxInfosManager.instance.getMailbox(id: mailboxId, userId: userId),
              let mailboxManager = accountManager.getMailboxManager(for: mailbox),
              let messageUid = content.userInfo[NotificationsHelper.UserInfoKeys.messageUid] as? String,
              !messageUid.isEmpty else {
            return false
        }

        switch identifier {
        case UNNotificationDefaultActionIdentifier:
            await messageActions.handleTapOnNotification(messageUid: messageUid, mailbox: mailbox, mailboxManager: mailboxManager)
            return true
        case NewMailActionIdentifier.archive:
            await messageActions.handleArchiveOnNotification(
                messageUid: messageUid,
                mailbox: mailbox,
                mailboxManager: mailboxManager
            )
            return true
        case NewMailActionIdentifier.delete:
            await messageActions.handleDeleteOnNotification(
                messageUid: messageUid,
                mailbox: mailbox,
                mailboxManager: mailboxManager
            )
            return true
        case NewMailActionIdentifier.reply:
            messageActions.handleReplyOnNotification(messageUid: messageUid, mailbox: mailbox, mailboxManager: mailboxManager)
            return true
        default:
            return false
        }
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse) async {
        Task {
            await handleMailAction(for: response.actionIdentifier, content: response.notification.request.content)
        }
    }
}
