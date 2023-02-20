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

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    private let notificationCenterDelegate = NotificationCenterDelegate()
    private var accountManager: AccountManager!
    static var orientationLock = UIInterfaceOrientationMask.all

    func application(_ application: UIApplication,
                     willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        Logging.initLogging()
        setupDI()
        DDLogInfo("Application starting in foreground ? \(UIApplication.shared.applicationState != .background)")
        accountManager = AccountManager.instance
        ApiFetcher.decoder.dateDecodingStrategy = .iso8601
        refreshCacheData()

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
            let userApiFetcher = accountManager.getApiFetcher(for: account.userId, token: account.token)
            Task {
                await notificationService.registerUserForRemoteNotificationsIfNeeded(tokenData: deviceToken,
                                                                                     userApiFetcher: userApiFetcher)
            }
        }
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
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }

    func refreshCacheData() {
        guard let currentAccount = AccountManager.instance.currentAccount else {
            return
        }

        Task {
            do {
                try await accountManager.updateUser(for: currentAccount, registerToken: true)
            } catch {
                DDLogError("Error while updating user account: \(error)")
            }
        }
    }

    func setupDI() {
        let loginService = Factory(type: InfomaniakLogin.self) { _, _ in
            InfomaniakLogin(clientId: MailApiFetcher.clientId)
        }
        let networkLoginService = Factory(type: InfomaniakNetworkLogin.self) { _, _ in
            InfomaniakNetworkLogin(clientId: MailApiFetcher.clientId)
        }
        let keychainHelper = Factory(type: KeychainHelper.self) { _, _ in
            KeychainHelper(accessGroup: AccountManager.accessGroup)
        }
        let notificationService = Factory(type: InfomaniakNotifications.self) { _, _ in
            InfomaniakNotifications()
        }
        let appLockHelper = Factory(type: AppLockHelper.self) { _, _ in
            AppLockHelper()
        }
        let bugTracker = Factory(type: BugTracker.self) { _, _ in
            BugTracker(info: BugTrackerInfo(project: "app-mobile-mail", gitHubRepoName: "ios-mail", appReleaseType: .beta))
        }

        SimpleResolver.sharedResolver.store(factory: loginService)
        SimpleResolver.sharedResolver.store(factory: networkLoginService)
        SimpleResolver.sharedResolver.store(factory: notificationService)
        SimpleResolver.sharedResolver.store(factory: keychainHelper)
        SimpleResolver.sharedResolver.store(factory: appLockHelper)
        SimpleResolver.sharedResolver.store(factory: bugTracker)
    }
}
