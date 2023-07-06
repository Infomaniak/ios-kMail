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
import InfomaniakBugTracker
import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import InfomaniakLogin
import InfomaniakNotifications
import MailCore
import Sentry
import SwiftUI
import UIKit

@main @available(iOSApplicationExtension, unavailable)
class AppDelegate: UIResponder, UIApplicationDelegate {
    private let notificationCenterDelegate = NotificationCenterDelegate()

    @LazyInjectService private var orientationManager: OrientationManageable
    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var applicationState: ApplicationStatable

    /// Making sure the DI is registered at a very early stage of the app launch.
    private let dependencyInjectionHook = EarlyDIHook()

    func application(_ application: UIApplication,
                     willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        Logging.initLogging()

        DDLogInfo("Application starting in foreground ? \(applicationState.applicationState != .background)")
        ApiFetcher.decoder.dateDecodingStrategy = .iso8601

        UNUserNotificationCenter.current().delegate = notificationCenterDelegate
        Task {
            // Ask permission app launch
            await NotificationsHelper.askForPermissions()
        }
        application.registerForRemoteNotifications()

        return true
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        @InjectService var notificationService: InfomaniakNotifications
        for account in accountManager.accounts {
            guard account.token != nil else { continue }
            let userApiFetcher = accountManager.getApiFetcher(for: account.userId, token: account.token)
            Task {
                await notificationService.updateRemoteNotificationsTokenIfNeeded(tokenData: deviceToken,
                                                                                 userApiFetcher: userApiFetcher)
            }
        }
    }

    /// Validate deeplinks
    func application(_ application: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Determine who sent the URL.
        let sendingAppID = options[.sourceApplication]
        DDLogInfo("source application = \(sendingAppID ?? "Unknown")")

        let absoluteString = url.absoluteString
        let success = absoluteString.starts(with: "mailto")
        DDLogInfo("URL handling = \(success ? "success" : "failure")")
        return success
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        DDLogError("Failed registering for notifications: \(error)")
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after
        // application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return orientationManager.orientationLock
    }
}
