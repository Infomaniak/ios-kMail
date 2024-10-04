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

    @LazyInjectService var accountManager: AccountManager

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
        guard let currentMailboxManager = accountManager.currentMailboxManager,
              let inboxFolder = currentMailboxManager.getFolder(with: .inbox),
              inboxFolder.cursor != nil else {
            // We do nothing if we don't have an initial cursor
            BGTaskScheduler.shared.cancelAllTaskRequests()
            return
        }

        // Every time we execute a task we schedule a new task for next time
        scheduleForBackgroundLaunch()

        await currentMailboxManager.refreshFolderContent(inboxFolder.freezeIfNeeded())

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
}
