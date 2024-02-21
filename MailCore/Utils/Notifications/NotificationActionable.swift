/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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
import MailResources
import UserNotifications

/// Something that can register notifications groups and actions related to them
public protocol NotificationActionsRegistrable {
    /// Registers the action available on an incoming mail.
    func registerEmailActionNotificationGroup()
}

/// Notification action group identifiers
public enum NotificationActionGroupIdentifier {
    /// Actions related to new email notifications
    public static let newMail = "com.infomaniak.mail.incoming"
}

public enum NewMailActionIdentifier {
    public static let archive = "com.infomaniak.mail.incoming.action.archive"
    public static let delete = "com.infomaniak.mail.incoming.action.delete"
    public static let reply = "com.infomaniak.mail.incoming.action.reply"
}

public struct NotificationActionsRegistrer: NotificationActionsRegistrable {
    public init() {
        // META: Keep SonarCloud happy
    }

    // MARK: - NotificationActionsRegistrable

    public func registerEmailActionNotificationGroup() {
        let archiveIconAsset = MailResourcesAsset.archives
        let archiveIcon = UNNotificationActionIcon(templateImageName: archiveIconAsset.name)
        let archiveAction = UNNotificationAction(
            identifier: NewMailActionIdentifier.archive,
            title: MailResourcesStrings.Localizable.actionArchive,
            options: [.authenticationRequired],
            icon: archiveIcon
        )

        let deleteIconAsset = MailResourcesAsset.bin
        let deleteIcon = UNNotificationActionIcon(templateImageName: deleteIconAsset.name)
        let deleteAction = UNNotificationAction(
            identifier: NewMailActionIdentifier.delete,
            title: MailResourcesStrings.Localizable.actionDelete,
            options: [.destructive, .authenticationRequired],
            icon: deleteIcon
        )

        let replyIconAsset = MailResourcesAsset.emailActionReply
        let replyIcon = UNNotificationActionIcon(templateImageName: replyIconAsset.name)
        let replyAction = UNNotificationAction(
            identifier: NewMailActionIdentifier.reply,
            title: MailResourcesStrings.Localizable.actionReply,
            options: [.foreground, .authenticationRequired],
            icon: replyIcon
        )

        let category = UNNotificationCategory(identifier: NotificationActionGroupIdentifier.newMail,
                                              actions: [archiveAction, replyAction, deleteAction],
                                              intentIdentifiers: [], options: [])

        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories([category])
    }
}
