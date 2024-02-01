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
import Contacts
import InfomaniakBugTracker
import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import InfomaniakLogin
import InfomaniakNotifications
import MailCore
import MailResources
import Sentry
import SwiftUI
import UIKit

@main
struct MailApp: App {
    /// Making sure the DI is registered at a very early stage of the app launch.
    private let dependencyInjectionHook = MailTargetAssembly()

    @LazyInjectService private var appLockHelper: AppLockHelper
    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var appLaunchCounter: AppLaunchCounter
    @LazyInjectService private var refreshAppBackgroundTask: RefreshAppBackgroundTask

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(UserDefaults.shared.key(.accentColor), store: .shared) private var accentColor = DefaultPreferences.accentColor
    @AppStorage(UserDefaults.shared.key(.theme), store: .shared) private var theme = DefaultPreferences.theme

    @StateObject private var navigationState = RootViewState()

    init() {
        DDLogInfo("Application starting in foreground ? \(UIApplication.shared.applicationState != .background)")
        refreshAppBackgroundTask.register()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .standardWindow()
                .environmentObject(navigationState)
                .onChange(of: scenePhase) { newScenePhase in
                    switch newScenePhase {
                    case .active:
                        appLaunchCounter.increase()
                        refreshCacheData()
                        navigationState.transitionToLockViewIfNeeded()
                        UserDefaults.shared.openingUntilReview -= 1
                    case .background:
                        refreshAppBackgroundTask.scheduleForBackgroundLaunchIfNeeded()
                        if UserDefaults.shared.isAppLockEnabled && navigationState.state != .appLocked {
                            appLockHelper.setTime()
                        }
                    case .inactive:
                        break
                    @unknown default:
                        break
                    }
                }
                .onChange(of: navigationState.account) { _ in
                    refreshCacheData()
                }
        }
        .defaultAppStorage(.shared)
        if #available(iOS 16.0, *) {
            WindowGroup(
                MailResourcesStrings.Localizable.settingsTitle,
                id: DesktopWindowIdentifier.settingsWindowIdentifier,
                for: SettingsViewConfig.self
            ) { $config in
                if case .mainView(let mailboxManager, _) = navigationState.state,
                   let baseNavigationPath = config?.baseNavigationPath {
                    SettingsNavigationView(baseNavigationPath: baseNavigationPath)
                        .standardWindow()
                        .environmentObject(navigationState)

                        .environmentObject(mailboxManager)
                }
            }
            .defaultAppStorage(.shared)
            WindowGroup(
                MailResourcesStrings.Localizable.settingsTitle,
                id: DesktopWindowIdentifier.composeWindowIdentifier,
                for: ComposeMessageIntent.self
            ) { $composeMessageIntent in
                if let composeMessageIntent {
                    ComposeMessageIntentView(composeMessageIntent: composeMessageIntent)
                        .standardWindow()
                        .environmentObject(navigationState)
                }
            }
            .defaultAppStorage(.shared)
        }
    }

    func refreshCacheData() {
        guard let account = navigationState.account else {
            return
        }

        Task {
            do {
                try await accountManager.updateUser(for: account)
                accountManager.enableBugTrackerIfAvailable()

                guard CNContactStore.authorizationStatus(for: .contacts) != .notDetermined else {
                    return
                }
                try await accountManager.currentContactManager?.refreshContactsAndAddressBooks()
            } catch {
                DDLogError("Error while updating user account: \(error)")
            }
        }
    }
}
