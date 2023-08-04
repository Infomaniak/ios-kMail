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

import Atlantis
import CocoaLumberjackSwift
import Foundation
import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import InfomaniakNotifications
import MailResources
import RealmSwift
import SwiftSoup
import UIKit
import UserNotifications

public enum NotificationsHelper {
    public enum CategoryIdentifier {
        public static let general = "com.mail.notification.general"
    }

    private enum NotificationIdentifier {
        static let disconnected = "accountDisconnected"
    }

    public enum UserInfoKeys {
        public static let userId = "user_id"
        public static let mailboxId = "mailbox_id"
        public static let messageUid = "message_uid"
    }

    public static var isNotificationEnabled: Bool {
        return UserDefaults.shared.isNotificationEnabled
    }

    public static func askForPermissions() async {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge, .providesAppNotificationSettings]
        do {
            try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        } catch {
            DDLogError("User has declined notifications")
        }
    }

    public static func getUnreadCount() async -> Int {
        var totalUnreadCount = 0
        @InjectService var notificationService: InfomaniakNotifications
        @InjectService var accountManager: AccountManager

        for account in accountManager.accounts {
            let currentSubscription = await notificationService.subscriptionForUser(id: account.userId)

            for mailbox in MailboxInfosManager.instance.getMailboxes(for: account.userId)
                where currentSubscription?.topics.contains(mailbox.notificationTopicName) == true {
                if let mailboxManager = accountManager.getMailboxManager(for: mailbox) {
                    totalUnreadCount += mailboxManager.getFolder(with: .inbox)?.unreadCount ?? 0
                }
            }
        }

        return totalUnreadCount
    }

    @MainActor
    public static func updateUnreadCountBadge() async {
        // Start a background task to update the app badge when going in the background
        var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "updateUnreadCountBadge task") {
            guard backgroundTaskIdentifier != .invalid else { return }
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
        }

        let totalUnreadCount = await getUnreadCount()

        UIApplication.shared.applicationIconBadgeNumber = totalUnreadCount
        if backgroundTaskIdentifier != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
        }
    }

    public static func sendDisconnectedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Error"
        content.body = "Refresh token error"
        content.categoryIdentifier = CategoryIdentifier.general
        content.sound = .default
        sendImmediately(notification: content, id: NotificationIdentifier.disconnected)
    }

    private static func sendImmediately(notification: UNMutableNotificationContent, id: String,
                                        action: IKSnackBar.Action? = nil) {
        DispatchQueue.main.async {
            @LazyInjectService var applicationState: ApplicationStatable
            let isInBackground = Bundle.main.isExtension || applicationState.applicationState != .active

            if isInBackground {
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
                let request = UNNotificationRequest(identifier: id, content: notification, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            } else {
                let snackbar = IKSnackBar.make(message: notification.body, duration: .lengthLong)
                if let action {
                    snackbar?.setAction(action).show()
                } else {
                    snackbar?.show()
                }
            }
        }
    }

    public static func generateNotificationFor(message: Message,
                                               mailboxId: Int,
                                               userId: Int) async -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        if !message.from.isEmpty {
            content.title = message.from.map(\.name).joined(separator: ",")
        } else {
            content.title = MailResourcesStrings.Localizable.unknownRecipientTitle
        }
        content.subtitle = message.formattedSubject
        content.body = getCleanBodyFrom(message: message)
        content.threadIdentifier = "\(mailboxId)_\(userId)"
        content.targetContentIdentifier = "\(userId)_\(mailboxId)_\(message.uid)"
        content.badge = await getUnreadCount() as NSNumber
        content.sound = .default
        content.userInfo = [NotificationsHelper.UserInfoKeys.userId: userId,
                            NotificationsHelper.UserInfoKeys.mailboxId: mailboxId,
                            NotificationsHelper.UserInfoKeys.messageUid: message.uid]
        return content
    }

    private static func getCleanBodyFrom(message: Message) -> String {
        guard let fullBody = message.body?.value,
              let bodyType = message.body?.type,
              let body = MessageBodyUtils.splitBodyAndQuote(messageBody: fullBody)?.messageBody else {
            return message.preview
        }

        guard bodyType != "text/plain" else {
            return body.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        do {
            let basicHtml = try SwiftSoup.clean(body, Whitelist.basic())!
            let parsedBody = try SwiftSoup.parse(basicHtml)

            let rawText = try parsedBody.text(trimAndNormaliseWhitespace: false)
            return rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return message.preview
        }
    }
}
