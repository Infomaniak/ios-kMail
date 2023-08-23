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

import CocoaLumberjackSwift
import InfomaniakCore
import InfomaniakDI
import InfomaniakNotifications
import MailCore
import UIKit

@available(iOSApplicationExtension, unavailable)
final class AppDelegate: UIResponder, UIApplicationDelegate {
    private let notificationCenterDelegate = NotificationCenterDelegate()

    @LazyInjectService private var orientationManager: OrientationManageable
    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var applicationState: ApplicationStatable

    /// Making sure the DI is registered at a very early stage of the app launch.
    private let dependencyInjectionHook = EarlyDIHook()

    func application(_ application: UIApplication,
                     willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        DDLogInfo("Application starting in foreground ? \(applicationState.applicationState != .background)")

        // Register actions for notifications of incoming emails.
        @InjectService var notificationActions: NotificationActionsRegistrable
        notificationActions.registerEmailActionNotificationGroup()

        UNUserNotificationCenter.current().delegate = notificationCenterDelegate
        Task {
            // Ask permission app launch
            await NotificationsHelper.askForPermissions()
        }
        application.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        @InjectService var notificationService: InfomaniakNotifications
        @InjectService var tokenStore: TokenStore

        for account in accountManager.accounts {
            Task {
                /* Because of a backend issue we can't register the notification token directly after the creation or refresh of
                 an API token. We wait at least 15 seconds before trying to register. */
                try? await Task.sleep(nanoseconds: 15_000_000_000)

                guard let token = tokenStore.tokenFor(userId: account.userId) else { return }
                let userApiFetcher = accountManager.getApiFetcher(for: token.userId, token: token)
                await notificationService.updateRemoteNotificationsToken(tokenData: deviceToken,
                                                                         userApiFetcher: userApiFetcher,
                                                                         updatePolicy: .always)
            }
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        DDLogError("Failed registering for notifications: \(error)")
    }

    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return orientationManager.orientationLock
    }
}
