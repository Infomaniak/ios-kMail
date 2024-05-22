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
import SwiftUI
import UIKit
import VersionChecker

struct UserAccountScene: Scene {
    @Environment(\.scenePhase) private var scenePhase

    @LazyInjectService private var appLockHelper: AppLockHelper
    @LazyInjectService private var appLaunchCounter: AppLaunchCounter
    @LazyInjectService private var refreshAppBackgroundTask: RefreshAppBackgroundTask
    @LazyInjectService private var reviewManager: ReviewManageable
    @LazyInjectService private var platformDetector: PlatformDetectable
    @LazyInjectService private var cacheManager: CacheManageable

    @StateObject private var rootViewState = RootViewState()

    var body: some Scene {
        WindowGroup(id: DesktopWindowIdentifier.mainWindowIdentifier(currentViewState: rootViewState)) {
            RootView()
                .standardWindow()
                .environmentObject(rootViewState)
                .onReceive(NotificationCenter.default.publisher(for: UIScene.willEnterForegroundNotification)) { _ in
                    /*
                     On iOS:
                     `scenePhase` changes each time a pop-up is presented.
                     We have to listen to `UIScene.willEnterForegroundNotification` to increase the `appLaunchCounter`
                     only when the app enters foreground.

                     On macOS:
                     `scenePhase` stays always active even when the app is on the background.
                     */

                    appLaunchCounter.increase()
                    cacheManager.refreshCacheData(account: rootViewState.account)
                    reviewManager.decreaseOpeningUntilReview()
                    rootViewState.transitionToLockViewIfNeeded()
                    checkAppVersion()
                }
                .onChange(of: scenePhase) { newScenePhase in
                    switch newScenePhase {
                    case .active:
                        break
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
                .task(id: rootViewState.account) {
                    cacheManager.refreshCacheData(account: rootViewState.account)
                }
        }
        .commands {
            CustomCommands(rootViewState: rootViewState)
        }
        .defaultAppStorage(.shared)

        // There is a crash if we target iOS 16.0
        if #available(iOS 16.1, *) {
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
                    if rootViewState.state == .updateRequired {
                        rootViewState.transitionToRootViewDestination(.mainView)
                    }
                }
            } catch {
                DDLogError("Error while checking version status: \(error)")
            }
        }
    }
}
