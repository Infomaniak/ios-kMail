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
import InfomaniakDI
import InfomaniakNotifications
import MailCore
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    private let notificationCenterDelegate = NotificationCenterDelegate()
    static var orientationLock = UIInterfaceOrientationMask.all

    func application(
        _ application: UIApplication,
        willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
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
        for account in AccountManager.instance.accounts {
            guard account.token != nil else { continue }
            let userApiFetcher = AccountManager.instance.getApiFetcher(for: account.userId, token: account.token)
            Task {
                await notificationService.updateRemoteNotificationsTokenIfNeeded(tokenData: deviceToken,
                                                                                 userApiFetcher: userApiFetcher)
            }
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        DDLogError("Failed registering for notifications: \(error)")
    }

    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}
