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

import Atlantis
import Foundation
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakDI
import InfomaniakNotifications
import Intents
import MailResources
import OSLog
import RealmSwift
import SwiftRegex
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
            Logger.general.error("User has declined notifications")
        }
    }

    public static func getUnreadCount() async -> Int {
        var totalUnreadCount = 0
        @InjectService var notificationService: InfomaniakNotifications
        @InjectService var accountManager: AccountManager
        @InjectService var mailboxInfosManager: MailboxInfosManager

        for account in accountManager.accounts {
            let currentSubscription = await notificationService.subscriptionForUser(id: account.userId)

            for mailbox in mailboxInfosManager.getMailboxes(for: account.userId)
                where currentSubscription?.topics.contains(mailbox.notificationTopicName) == true {
                if let mailboxManager = accountManager.getMailboxManager(for: mailbox) {
                    totalUnreadCount += mailboxManager.getFolder(with: .inbox)?.unreadCount ?? 0
                }
            }
        }

        return totalUnreadCount
    }

    public static func fetchMessage(uid: String, in mailboxManager: MailboxManager) async throws -> Message? {
        guard let inboxFolder = mailboxManager.getFolder(with: .inbox),
              inboxFolder.cursor != nil else {
            // We do nothing if we don't have an initial cursor
            return nil
        }
        await mailboxManager.refreshFolderContent(inboxFolder.freezeIfNeeded())

        @ThreadSafe var message = mailboxManager.fetchObject(ofType: Message.self, forPrimaryKey: uid)

        if let message,
           !message.fullyDownloaded {
            try await mailboxManager.message(message: message)
        }

        message?.realm?.refresh()
        return message?.freezeIfNeeded()
    }

    public static func clearAlreadyReadNotifications(shouldWait: Bool = false) async {
        let notificationCenter = UNUserNotificationCenter.current()
        let deliveredNotifications = await notificationCenter.deliveredNotifications()

        var notificationIdsToRemove = Set<String>()
        for notification in deliveredNotifications where shouldRemoveNotification(notification) {
            notificationIdsToRemove.insert(notification.request.identifier)
        }

        guard !notificationIdsToRemove.isEmpty else { return }
        notificationCenter.removeDeliveredNotifications(withIdentifiers: Array(notificationIdsToRemove))

        guard !shouldWait else { return }
        // We have to wait at least 500ms if we are in the extension because removeDeliveredNotifications is executed in the
        // background and iOS kills the extension before removeDeliveredNotifications is executed
        try? await Task.sleep(nanoseconds: UInt64(0.5 * Double(NSEC_PER_SEC)))
    }

    private static func shouldRemoveNotification(_ notification: UNNotification) -> Bool {
        @InjectService var accountManager: AccountManager
        @InjectService var mailboxInfosManager: MailboxInfosManager

        // Message should exist for the given mailbox, it should be in the inbox and should be unread
        let content = notification.request.content
        guard let mailboxId = content.userInfo[NotificationsHelper.UserInfoKeys.mailboxId] as? Int,
              let userId = content.userInfo[NotificationsHelper.UserInfoKeys.userId] as? Int,
              let mailbox = mailboxInfosManager.getMailbox(id: mailboxId, userId: userId),
              let mailboxManager = accountManager.getMailboxManager(for: mailbox),
              let messageUid = content.userInfo[NotificationsHelper.UserInfoKeys.messageUid] as? String,
              !messageUid.isEmpty,
              let message = mailboxManager.fetchObject(ofType: Message.self, forPrimaryKey: messageUid),
              message.folder?.role == .inbox,
              !message.seen
        else {
            return true
        }

        return false
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
        content.title = MailResourcesStrings.Localizable.errorLoginTitle
        content.body = MailResourcesStrings.Localizable.refreshTokenError
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

    public static func generateBaseNotificationFor(message: Message,
                                                   mailboxId: Int,
                                                   userId: Int,
                                                   incompleteNotification: UNMutableNotificationContent) async {
        incompleteNotification.threadIdentifier = "\(mailboxId)_\(userId)"
        incompleteNotification.targetContentIdentifier = "\(userId)_\(mailboxId)_\(message.uid)"
        incompleteNotification.badge = await getUnreadCount() as NSNumber
        incompleteNotification.sound = .default
        incompleteNotification.categoryIdentifier = NotificationActionGroupIdentifier.newMail // enable actions
        if #available(iOS 16.0, *) {
            incompleteNotification.filterCriteria = MailboxInfosManager.getObjectId(mailboxId: mailboxId, userId: userId)
        }
        incompleteNotification.userInfo = [NotificationsHelper.UserInfoKeys.userId: userId,
                                           NotificationsHelper.UserInfoKeys.mailboxId: mailboxId,
                                           NotificationsHelper.UserInfoKeys.messageUid: message.uid]
    }

    public static func generateNotificationFor(message: Message,
                                               incompleteNotification: UNMutableNotificationContent)
        async -> UNMutableNotificationContent {
        if !message.from.isEmpty {
            incompleteNotification.title = message.from.map(\.name).joined(separator: ",")
        } else {
            incompleteNotification.title = MailResourcesStrings.Localizable.unknownRecipientTitle
        }
        incompleteNotification.subtitle = message.formattedSubject
        incompleteNotification.body = await getCleanBodyFrom(message: message)
        return incompleteNotification
    }

    public static func generateCompleteNotification(
        fetchedMessage: Message,
        mailboxManager: MailboxManager,
        incompleteNotification: UNMutableNotificationContent
    ) async -> UNNotificationContent {
        if let fromRecipient = fetchedMessage.from.first,
           let communicationNotification = await generateCommunicationNotificationFor(
               message: fetchedMessage,
               fromRecipient: fromRecipient,
               mailboxManager: mailboxManager,
               incompleteNotification: incompleteNotification
           ) {
            return communicationNotification
        } else {
            let normalNotification = await generateNotificationFor(
                message: fetchedMessage,
                incompleteNotification: incompleteNotification
            )
            return normalNotification
        }
    }

    public static func generateCommunicationNotificationFor(
        message: Message,
        fromRecipient: Recipient,
        mailboxManager: MailboxManager,
        incompleteNotification: UNMutableNotificationContent
    ) async -> UNNotificationContent? {
        let localContact = mailboxManager.contactManager.getContact(for: fromRecipient)
        let handleSender = INPersonHandle(value: fromRecipient.email, type: .emailAddress)
        let sender = INPerson(personHandle: handleSender,
                              nameComponents: nil,
                              displayName: localContact?.name ?? fromRecipient.name,
                              image: nil,
                              contactIdentifier: localContact?.localIdentifier,
                              customIdentifier: nil)

        let handleRecipient = INPersonHandle(value: MailResourcesStrings.Localizable.contactMe, type: .unknown)
        let recipient = INPerson(personHandle: handleRecipient,
                                 nameComponents: nil,
                                 displayName: MailResourcesStrings.Localizable.contactMe,
                                 image: nil,
                                 contactIdentifier: localContact?.localIdentifier,
                                 customIdentifier: nil,
                                 isMe: true)

        let body = await getCleanBodyFrom(message: message)
        let subtitle = message.formattedSubject
        incompleteNotification.body = body

        let intent = INSendMessageIntent(recipients: [sender, recipient],
                                         outgoingMessageType: .outgoingMessageText,
                                         content: body,
                                         speakableGroupName: INSpeakableString(spokenPhrase: subtitle),
                                         conversationIdentifier: message.uid,
                                         serviceName: nil,
                                         sender: sender,
                                         attachments: nil)

        let interaction = INInteraction(intent: intent, response: nil)

        interaction.direction = .incoming

        do {
            try await interaction.donate()
            let updatedContent = try incompleteNotification.updating(from: intent)

            return updatedContent

        } catch {
            return nil
        }
    }

    public static func updateMessagePreview(
        with notification: UNNotificationContent,
        message: Message,
        mailboxManager: MailboxManager
    ) async {
        try? mailboxManager.writeTransaction { realm in
            guard let liveMessage = realm.object(ofType: Message.self, forPrimaryKey: message.uid) else {
                return
            }

            liveMessage.preview = String(notification.body.prefix(512))
        }
    }

    public static func getCleanEmojiPreviewFrom(message: Message) -> String {
        guard let emojiReaction = message.emojiReaction, let firstFrom = message.from.first else {
            return message.preview
        }

        let name: String
        if !firstFrom.name.isEmpty {
            name = firstFrom.name
        } else {
            name = firstFrom.email
        }

        let preview = MailResourcesStrings.Localizable.previewReaction(name, emojiReaction)
        return preview
    }

    public static func getCleanBodyFrom(message: Message) async -> String {
        if message.emojiReaction != nil {
            return getCleanEmojiPreviewFrom(message: message)
        }

        guard let fullBody = message.body?.value,
              let bodyType = message.body?.type else {
            return message.preview
        }

        guard bodyType != .textPlain else {
            return compactBody(from: fullBody) ?? message.preview
        }

        do {
            let body = await MessageBodyUtils.splitBodyAndQuote(messageBody: fullBody).messageBody
            let cleanedDocument = try await SwiftSoupUtils(fromHTML: body).cleanBody()
            guard let extractedBody = cleanedDocument.body() else { return message.preview }

            let rawText = try extractedBody.text(trimAndNormaliseWhitespace: false)

            return compactBody(from: rawText) ?? message.preview
        } catch {
            return message.preview
        }
    }

    private static func compactBody(from body: String) -> String? {
        guard let regex = Regex(pattern: #"\s+"#) else { return nil }
        let cleanedText = regex.replaceMatches(in: body, with: " ").trimmedAndWithoutNewlines

        return cleanedText
    }
}
