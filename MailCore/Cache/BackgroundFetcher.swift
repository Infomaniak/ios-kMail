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

import BackgroundTasks
import Foundation
import MailResources
import RealmSwift
import UIKit
import UserNotifications

public class BackgroundFetcher {
    public static let shared = BackgroundFetcher()

    private init() {}

    public func handleAppRefresh(refreshTask: BGAppRefreshTask) {
        let fetchMailsTask = Task {
            await fetchLastEmailsForAllMailboxes()
            refreshTask.setTaskCompleted(success: true)
        }
        refreshTask.expirationHandler = {
            fetchMailsTask.cancel()
        }
    }

    public func fetchLastEmailsForAllMailboxes() async {
        await withTaskGroup(of: Void.self) { group in
            for mailbox in MailboxInfosManager.instance.getMailboxes() {
                if let mailboxManager = AccountManager.instance.getMailboxManager(for: mailbox) {
                    group.addTask {
                        do {
                            try await self.fetchEmailsFor(mailboxManager: mailboxManager)
                        } catch {}
                    }
                }
            }
        }
    }

    private func fetchEmailsFor(mailboxManager: MailboxManager) async throws {
        guard let inboxFolder = mailboxManager.getFolder(with: .inbox),
              inboxFolder.cursor != nil else {
            // We do nothing if we don't have an initial cursor
            return
        }

        let inboxFolderId = inboxFolder.id
        let lastUnreadDate = mailboxManager.getRealm().objects(Message.self)
            .where { $0.seen == false && $0.folderId == inboxFolderId }
            .sorted(by: \.date, ascending: false)
            .first?.date ?? Date(timeIntervalSince1970: 0)
        try await mailboxManager.threads(folder: inboxFolder)

        let realm = mailboxManager.getRealm()
        let newUnreadMessages = realm.objects(Message.self)
            .where {
                $0.seen == false
                    && $0.date > lastUnreadDate
                    && $0.folderId == inboxFolderId
            }

        for message in newUnreadMessages {
            let threadUid = mailboxManager.getFolder(with: .inbox, using: realm)?.threads.where {
                $0.messages.contains(message)
            }.first?.uid
            triggerNotificationFor(message: message, threadUid: threadUid, mailboxId: mailboxManager.mailbox.objectId)
        }
        
        NotificationsHelper.updateUnreadCountBadge()
    }

    private func triggerNotificationFor(message: Message, threadUid: String?, mailboxId: String) {
        let content = UNMutableNotificationContent()
        if !message.from.isEmpty {
            content.title = message.from.map { $0.name }.joined(separator: ",")
        } else {
            content.title = MailResourcesStrings.Localizable.unknownRecipientTitle
        }
        content.subtitle = message.formattedSubject
        content.body = message.preview
        if let threadUid {
            content.threadIdentifier = threadUid
        }
        content.targetContentIdentifier = message.uid
        content.userInfo = [NotificationsHelper.UserInfoKeys.mailboxId: mailboxId]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let notificationId = "\(mailboxId)-\(message.uid)"
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
