/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import BackgroundTasks
import Foundation
import InfomaniakConcurrency
import InfomaniakDI
import OSLog
import SwiftUI

/// A type that represents a [task that can be executed in the background](https://developer.apple.com/documentation/uikit/app_and_environment/scenes/preparing_your_ui_to_run_in_the_background/using_background_tasks_to_update_your_app)
public protocol BackgroundTaskable {
    /// Schedule the task for next background launch, only if needed
    func scheduleForBackgroundLaunchIfNeeded()

    /// Schedule the task for next background launch
    func scheduleForBackgroundLaunch()

    /// Ask the system to register the task
    func register()

    /// The method that actually executes when background task is called
    func run() async
}

public class RefreshAppBackgroundTask: BackgroundTaskable {
    let backgroundTaskIdentifier = "com.infomaniak.mail.background-refresh"

    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var mailboxInfosManager: MailboxInfosManager

    public init() {
        // Exposed for DI
    }

    public func scheduleForBackgroundLaunchIfNeeded() {
        guard !accountManager.accounts.isEmpty else { return }
        scheduleForBackgroundLaunch()
    }

    public func scheduleForBackgroundLaunch() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        // Fetch no earlier than 15 minutes from now
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            Logger.general.error("Could not schedule app refresh: \(error)")
        }
    }

    public func run() async {
        guard !accountManager.accounts.isEmpty else {
            BGTaskScheduler.shared.cancelAllTaskRequests()
            return
        }

        let mailboxWithNotificationsObjectIds = await getMailboxWithNotifications()
        let mailboxWithUnreadObjectIds = getMailboxWithUnreadMessages()

        let uniqueMailboxObjectIds = Set(mailboxWithNotificationsObjectIds + mailboxWithUnreadObjectIds)

        let mailboxManagersToRefresh: [(MailboxManager, Folder)] = uniqueMailboxObjectIds.compactMap { mailboxObjectId in
            guard let mailbox = mailboxInfosManager.getMailbox(objectId: mailboxObjectId),
                  let mailboxManager = accountManager.getMailboxManager(for: mailbox),
                  let inboxFolder = mailboxManager.getFolder(with: .inbox)?.freezeIfNeeded(),
                  inboxFolder.cursor != nil else {
                return nil
            }

            return (mailboxManager, inboxFolder)
        }

        guard !mailboxManagersToRefresh.isEmpty else {
            BGTaskScheduler.shared.cancelAllTaskRequests()
            return
        }

        // Only reschedule if we have at least one mailbox correctly init
        scheduleForBackgroundLaunch()

        await mailboxManagersToRefresh.concurrentForEach { mailboxManager, inboxFolder in
            await mailboxManager.refreshFolderContent(inboxFolder)
        }

        await NotificationsHelper.clearAlreadyReadNotifications()

        await NotificationsHelper.updateUnreadCountBadge()
    }

    @available(iOS, deprecated: 16, message: "Use Scene.backgroundTask")
    public func register() {
        BGTaskScheduler.shared
            .register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
                guard let refreshTask = task as? BGAppRefreshTask else { return }

                let handleAppRefresh = Task {
                    await self.run()
                    refreshTask.setTaskCompleted(success: true)
                }

                refreshTask.expirationHandler = {
                    handleAppRefresh.cancel()
                }
            }
    }

    private func getMailboxWithNotifications() async -> [String] {
        let notificationCenter = UNUserNotificationCenter.current()
        let deliveredNotifications = await notificationCenter.deliveredNotifications()

        let mailboxObjectIds: [String] = deliveredNotifications.compactMap { notification in
            let content = notification.request.content

            guard let mailboxId = content.userInfo[NotificationsHelper.UserInfoKeys.mailboxId] as? Int,
                  let userId = content.userInfo[NotificationsHelper.UserInfoKeys.userId] as? Int else {
                return nil
            }

            return MailboxInfosManager.getObjectId(mailboxId: mailboxId, userId: userId)
        }

        return mailboxObjectIds
    }

    private func getMailboxWithUnreadMessages() -> [String] {
        let mailboxObjectIds: [String] = accountManager.accounts.compactMap { account in
            for mailbox in mailboxInfosManager.getMailboxes(for: account.userId) {
                if let mailboxManager = accountManager.getMailboxManager(for: mailbox),
                   (mailboxManager.getFolder(with: .inbox)?.unreadCount ?? 0) > 0 {
                    return mailbox.objectId
                }
            }
            return nil
        }

        return mailboxObjectIds
    }
}
