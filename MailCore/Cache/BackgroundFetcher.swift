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
import CocoaLumberjackSwift
import Foundation
import MailResources
import RealmSwift
import UIKit
import UserNotifications

public class BackgroundFetcher {
    public static let shared = BackgroundFetcher()

    private init() {}

    public func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Constants.backgroundRefreshTaskIdentifier, using: nil) { task in
            self.scheduleAppRefresh()
            self.handleAppRefresh(refreshTask: task as! BGAppRefreshTask)
        }
    }

    public func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Constants.backgroundRefreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
            DDLogInfo("[BackgroundFetcher] Scheduled background fetch task \(Constants.backgroundRefreshTaskIdentifier)")
        } catch {
            DDLogError("[BackgroundFetcher] Error scheduling background fetch task \(error)")
        }
    }

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
        let lastMessageDate = mailboxManager.getRealm().objects(Message.self)
            .where { $0.folderId == inboxFolderId }
            .sorted(by: \.date, ascending: false)
            .first?.date ?? Date(timeIntervalSince1970: 0)
        try await mailboxManager.threads(folder: inboxFolder)

        let newUnreadMessages = mailboxManager.getRealm().objects(Message.self)
            .where {
                $0.seen == false
                    && $0.date > lastMessageDate
                    && $0.folderId == inboxFolderId
            }
            .map { $0.freeze() }
            .toArray()

        for message in newUnreadMessages {
            try await mailboxManager.message(message: message)
            NotificationsHelper.triggerNotificationFor(
                message: message,
                mailboxId: mailboxManager.mailbox.objectId
            )
        }

        NotificationsHelper.updateUnreadCountBadge()
    }
}
