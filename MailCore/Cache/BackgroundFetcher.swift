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
import RealmSwift
import UserNotifications

public class BackgroundFetcher {
    public static let shared = BackgroundFetcher()

    private init() {}

    public func fetchLastEmailsForAllMailboxes() {
        Task {
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
    }

    private func fetchEmailsFor(mailboxManager: MailboxManager) async throws {
        guard let inboxFolder = mailboxManager.getFolder(with: .inbox),
              inboxFolder.cursor != nil else {
            // We do nothing if we don't have an initial cursor
            return
        }

        let lastUnreadDate = mailboxManager.getRealm().objects(Message.self)
            .where { $0.seen == false }
            .sorted(by: \.date, ascending: true)
            .first?.date ?? Date(timeIntervalSince1970: 0)
        try await mailboxManager.threads(folder: inboxFolder)

        let newUnreadMessages = mailboxManager.getRealm().objects(Message.self)
            .where { $0.seen == false && $0.date > lastUnreadDate }

        for message in newUnreadMessages {
            triggerNotificationFor(message: message)
        }
    }

    private func triggerNotificationFor(message: Message) {
        let content = UNMutableNotificationContent()
        // TODO: Handle multiple senders
        if let sender = message.from.first {
            content.title = sender.name
        } else {
            content.title = "Unknown sender"
        }
        content.subtitle = message.formattedSubject
        content.body = message.preview

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: message.uid, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
