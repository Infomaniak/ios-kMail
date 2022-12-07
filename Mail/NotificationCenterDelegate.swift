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
import MailCore
import UIKit
import UserNotifications

@MainActor
class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    private func handleClickOnNotification(scene: UIScene?, content: UNNotificationContent) {
        guard let mailboxId = content.userInfo[NotificationsHelper.UserInfoKeys.mailboxId] as? String,
              let mailbox = MailboxInfosManager.instance.getMailbox(objectId: mailboxId),
              let mailboxManager = AccountManager.instance.getMailboxManager(for: mailbox) else {
            return
        }

        if AccountManager.instance.currentMailboxManager?.mailbox != mailboxManager.mailbox {
            if AccountManager.instance.currentAccount.userId != mailboxManager.mailbox.userId {
                // (scene.delegate.delegate as? SceneDelegate)?.switchMailbox(mailbox)
            } else {
                // (scene.delegate.delegate as? SceneDelegate)?.switchMailbox(mailbox)
            }
        }
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            handleClickOnNotification(scene: response.targetScene, content: response.notification.request.content)
        default:
            break
        }
    }
}
