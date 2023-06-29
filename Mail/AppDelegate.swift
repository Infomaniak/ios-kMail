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

    func application(_ application: UIApplication,
                     willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        Logging.initLogging()
        setupDI()
        DDLogInfo("Application starting in foreground ? \(UIApplication.shared.applicationState != .background)")
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

    func refreshCacheData() {
        guard let currentAccount = accountManager.currentAccount else {
            return
        }

        Task {
            do {
                try await accountManager.updateUser(for: currentAccount)
                accountManager.enableBugTrackerIfAvailable()

                try await accountManager.currentContactManager?.fetchContactsAndAddressBooks()
            } catch {
                DDLogError("Error while updating user account: \(error)")
            }
        }
    }

    func setupDI() {
        let networkLoginService = Factory(type: InfomaniakNetworkLoginable.self) { _, _ in
            InfomaniakNetworkLogin(clientId: MailApiFetcher.clientId)
        }
        let loginService = Factory(type: InfomaniakLoginable.self) { _, _ in
            InfomaniakLogin(clientId: MailApiFetcher.clientId)
        }
        let keychainHelper = Factory(type: KeychainHelper.self) { _, _ in
            KeychainHelper(accessGroup: AccountManager.accessGroup)
        }
        let notificationService = Factory(type: InfomaniakNotifications.self) { _, _ in
            InfomaniakNotifications(appGroup: AccountManager.appGroup)
        }
        let appLockHelper = Factory(type: AppLockHelper.self) { _, _ in
            AppLockHelper()
        }
        let bugTracker = Factory(type: BugTracker.self) { _, _ in
            BugTracker(info: BugTrackerInfo(project: "app-mobile-mail", gitHubRepoName: "ios-mail", appReleaseType: .beta))
        }
        let matomoUtils = Factory(type: MatomoUtils.self) { _, _ in
            MatomoUtils(siteId: Constants.matomoId, baseURL: URLConstants.matomo.url)
        }
        let avoider = Factory(type: SnackBarAvoider.self) { _, _ in
            SnackBarAvoider()
        }
        let draftManager = Factory(type: DraftManager.self) { _, _ in
            DraftManager()
        }
        let accountManager = Factory(type: AccountManager.self) { _, _ in
            AccountManager()
        }

        SimpleResolver.sharedResolver.store(factory: networkLoginService)
        SimpleResolver.sharedResolver.store(factory: loginService)
        SimpleResolver.sharedResolver.store(factory: notificationService)
        SimpleResolver.sharedResolver.store(factory: keychainHelper)
        SimpleResolver.sharedResolver.store(factory: appLockHelper)
        SimpleResolver.sharedResolver.store(factory: bugTracker)
        SimpleResolver.sharedResolver.store(factory: matomoUtils)
        SimpleResolver.sharedResolver.store(factory: avoider)
        SimpleResolver.sharedResolver.store(factory: draftManager)
        SimpleResolver.sharedResolver.store(factory: accountManager)

        setupProxyInDI()
    }

    private func setupProxyInDI() {
        let factories = [
            Factory(type: CacheManageable.self) { _, _ in
                CacheManager()
            },
            Factory(type: OrientationManageable.self) { _, _ in
                OrientationManager()
            },
            Factory(type: RemoteNotificationRegistrable.self) { _, _ in
                RemoteNotificationRegistrer()
            },
            Factory(type: RootViewManageable.self) { _, _ in
                RootViewManager()
            },
            Factory(type: URLNavigable.self) { _, _ in
                URLNavigator()
            }
        ]

        factories.forEach { SimpleResolver.sharedResolver.store(factory: $0) }
    }
}
