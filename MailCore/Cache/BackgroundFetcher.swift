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
            await fetchLastMessagesForAllMailboxes()
            refreshTask.setTaskCompleted(success: true)
        }
        refreshTask.expirationHandler = {
            fetchMailsTask.cancel()
        }
    }

    public func fetchLastMessagesForAllMailboxes() async {
        await withTaskGroup(of: Void.self) { group in
            for mailbox in MailboxInfosManager.instance.getMailboxes() {
                guard let mailboxManager = AccountManager.instance.getMailboxManager(for: mailbox) else { continue }
                group.addTask {
                    do {
                        try await self.fetchAllUnreadMessagesFor(mailboxManager: mailboxManager)
                    } catch {}
                }
            }
        }
    }

    public func fetchMessage(uid: String, in mailboxManager: MailboxManager) async throws -> Message? {
        guard let inboxFolder = mailboxManager.getFolder(with: .inbox),
              inboxFolder.cursor != nil else {
            // We do nothing if we don't have an initial cursor
            return nil
        }
        try await mailboxManager.threads(folder: inboxFolder.freezeIfNeeded())

        @ThreadSafe var message = mailboxManager.getRealm().object(ofType: Message.self, forPrimaryKey: uid)

        if let message,
           !message.fullyDownloaded {
            try await mailboxManager.message(message: message)
        }

        message?.realm?.refresh()
        return message?.freezeIfNeeded()
    }

    public func fetchAllUnreadMessagesFor(mailboxManager: MailboxManager) async throws {
        guard let inboxFolder = mailboxManager.getFolder(with: .inbox),
              inboxFolder.cursor != nil else {
            // We do nothing if we don't have an initial cursor
            return
        }
        @ThreadSafe var threadSafeInboxFolder = inboxFolder

        let lastMessageDate = threadSafeInboxFolder?.messages
            .sorted(by: \.date, ascending: false)
            .first?.date ?? Date(timeIntervalSince1970: 0)

        try await mailboxManager.threads(folder: inboxFolder.freezeIfNeeded())

        threadSafeInboxFolder?.realm?.refresh()
        let newUnreadMessages = threadSafeInboxFolder?.messages
            .where { $0.seen == false && $0.date > lastMessageDate }
            .map { $0.freeze() }
            .toArray() ?? []

        for message in newUnreadMessages {
            try await mailboxManager.message(message: message)
        }
    }
}
