/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import VersionChecker

struct UserAccountScene: Scene {
    @Environment(\.scenePhase) private var scenePhase

    @LazyInjectService private var appLockHelper: AppLockHelper
    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var appLaunchCounter: AppLaunchCounter
    @LazyInjectService private var refreshAppBackgroundTask: RefreshAppBackgroundTask
    @LazyInjectService private var platformDetector: PlatformDetectable

    @StateObject private var rootViewState = RootViewState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .standardWindow()
                .environmentObject(rootViewState)
                .onChange(of: scenePhase) { newScenePhase in
                    switch newScenePhase {
                    case .active:
                        appLaunchCounter.increase()
                        refreshCacheData()
                        rootViewState.transitionToLockViewIfNeeded()
                        checkAppVersion()
                        UserDefaults.shared.openingUntilReview -= 1
                    case .background:
                        refreshAppBackgroundTask.scheduleForBackgroundLaunchIfNeeded()
                        if UserDefaults.shared.isAppLockEnabled && rootViewState.state != .appLocked {
                            appLockHelper.setTime()
                        }
                    case .inactive:
                        break
                    @unknown default:
                        break
                    }
                }
                .onChange(of: rootViewState.account) { _ in
                    refreshCacheData()
                }
        }
        .commands {
            CustomCommands(rootViewState: rootViewState)
        }
        .defaultAppStorage(.shared)

        if #available(iOS 16.0, *) {
            WindowGroup(
                MailResourcesStrings.Localizable.settingsTitle,
                id: DesktopWindowIdentifier.settingsWindowIdentifier,
                for: SettingsViewConfig.self
            ) { $config in
                if case .mainView(let mainViewState) = rootViewState.state,
                   let baseNavigationPath = config?.baseNavigationPath {
                    SettingsNavigationView(baseNavigationPath: baseNavigationPath)
                        .standardWindow()
                        .environmentObject(mainViewState.mailboxManager)
                }
            }
            .defaultAppStorage(.shared)
        }
    }

    func refreshCacheData() {
        guard let account = rootViewState.account else {
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

    func checkAppVersion() {
        Task {
            do {
                let platform: Platform = platformDetector.isMacCatalyst ? .macOS : .ios
                let versionStatus = try await VersionChecker.standard.checkAppVersionStatus(platform: platform)
                switch versionStatus {
                case .updateIsRequired:
                    rootViewState.transitionToRootViewDestination(.updateRequired)
                case .canBeUpdated:
                    if case .mainView(let mainViewState) = rootViewState.state {
                        mainViewState.isShowingUpdateAvailable = true
                    }
                case .isUpToDate:
                    break
                }
            } catch {
                DDLogError("Error while checking version status: \(error)")
            }
        }
    }
}
