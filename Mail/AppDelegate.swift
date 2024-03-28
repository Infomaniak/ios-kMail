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
    private let quickActionService = QuickActionService.shared

    @LazyInjectService private var orientationManager: OrientationManageable
    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var applicationState: ApplicationStatable
    @LazyInjectService private var notificationService: InfomaniakNotifications
    @LazyInjectService private var tokenStore: TokenStore
    @LazyInjectService private var notificationActions: NotificationActionsRegistrable
    @LazyInjectService private var draftManager: DraftManager
    @LazyInjectService private var platformDetector: PlatformDetectable

    func application(_ application: UIApplication,
                     willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Prevent window restoration on macOS
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")

        DDLogInfo("Application starting in foreground ? \(applicationState.applicationState != .background)")

        // Register actions for notifications of incoming emails.
        notificationActions.registerEmailActionNotificationGroup()

        UNUserNotificationCenter.current().delegate = notificationCenterDelegate
        application.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
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

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        guard platformDetector.isMac,
              let currentMailboxManager = accountManager.currentMailboxManager else {
            return
        }
        draftManager.syncDraft(mailboxManager: currentMailboxManager, showSnackbar: false)
    }

    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        NotificationCenter.default.post(name: .userPerformedShortcut, object: shortcutItem)
        completionHandler(true)
    }

//    func application(
//        _ application: UIApplication,
//        configurationForConnecting connectingSceneSession: UISceneSession,
//        options: UIScene.ConnectionOptions
//    ) -> UISceneConfiguration {
//        /// Unwrap shortcutItem provided with the options. If it’s present, this indicates that the user is launching the app
//        /from
//        /// a quick action.
//        if let shortcutItem = options.shortcutItem {
//            quickActionService.quickAction = QuickAction(shortcutItem: shortcutItem)
//        }
//
//        /// Creating the appropriate UISceneConfiguration object and returning it.
//        let configuration = UISceneConfiguration(
//            name: connectingSceneSession.configuration.name,
//            sessionRole: connectingSceneSession.role
//        )
//        configuration.delegateClass = SceneDelegate.self
//        return configuration
//    }
//
//    class SceneDelegate: NSObject, UIWindowSceneDelegate {
//        private let quickActionService = QuickActionService.shared
//
//        /// to hook into events that trigger when a user interacts with a quick action
//        func windowScene(
//            _ windowScene: UIWindowScene,
//            performActionFor shortcutItem: UIApplicationShortcutItem,
//            completionHandler: @escaping (Bool) -> Void
//        ) {
//            /// Attempt to convert UIApplicationShortcutItem into an Action and pass it onto the ActionService.
//            quickActionService.quickAction = QuickAction(shortcutItem: shortcutItem)
//            completionHandler(true)
//        }
//    }
}
