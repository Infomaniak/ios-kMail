/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

import Contacts
import InfomaniakBugTracker
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import InfomaniakLogin
import InfomaniakNotifications
import MailCore
import MailCoreUI
import MailResources
import OSLog
import SwiftUI
import UIKit
import VersionChecker

struct UserAccountScene: Scene {
    @LazyInjectService private var appLockHelper: AppLockHelper
    @LazyInjectService private var appLaunchCounter: AppLaunchCounter
    @LazyInjectService private var refreshAppBackgroundTask: RefreshAppBackgroundTask
    @LazyInjectService private var reviewManager: ReviewManageable
    @LazyInjectService private var platformDetector: PlatformDetectable

    @StateObject private var rootViewState = RootViewState()

    var body: some Scene {
        WindowGroup(id: DesktopWindowIdentifier.mainWindowIdentifier) {
            RootView()
                .standardWindow()
                .environmentObject(rootViewState)
                .sceneLifecycle(willEnterForeground: willEnterForeground, didEnterBackground: didEnterBackground)
        }
        .commands {
            CustomCommands(rootViewState: rootViewState)
        }
        .defaultAppStorage(.shared)

        WindowGroup(
            MailResourcesStrings.Localizable.settingsTitle,
            id: DesktopWindowIdentifier.settingsWindowIdentifier,
            for: SettingsViewConfig.self
        ) { $config in
            if case .mainView(let user, let mainViewState) = rootViewState.state,
               let baseNavigationPath = config?.baseNavigationPath {
                SettingsNavigationView(baseNavigationPath: baseNavigationPath)
                    .standardWindow()
                    .environmentObject(mainViewState.mailboxManager)
                    .environment(\.currentUser, MandatoryEnvironmentContainer(value: user))
            }
        }
        .defaultAppStorage(.shared)
    }

    private func willEnterForeground() {
        if rootViewState.state != .onboarding && rootViewState.state != .preloading {
            appLaunchCounter.increase()
            reviewManager.decreaseActionUntilReview()
        }
        rootViewState.transitionToLockViewIfNeeded()
        checkAppVersion()
    }

    private func didEnterBackground() {
        refreshAppBackgroundTask.scheduleForBackgroundLaunchIfNeeded()
        if UserDefaults.shared.isAppLockEnabled && rootViewState.state != .appLocked {
            appLockHelper.setTime()
        }
    }

    private func checkAppVersion() {
        guard !platformDetector.isRunningUITests else { return }
        Task {
            do {
                let platform: Platform = platformDetector.isMacCatalyst ? .macOS : .ios
                let versionStatus = try await VersionChecker.standard.checkAppVersionStatus(platform: platform)
                switch versionStatus {
                case .updateIsRequired:
                    rootViewState.transitionToRootViewState(.updateRequired)
                case .canBeUpdated:
                    if case .mainView(_, let mainViewState) = rootViewState.state {
                        mainViewState.isShowingUpdateAvailable = true
                    }
                case .isUpToDate:
                    if rootViewState.state == .updateRequired {
                        await rootViewState.transitionToMainViewIfPossible(targetAccount: nil, targetMailbox: nil)
                    }
                }
            } catch {
                Logger.general.error("Error while checking version status: \(error)")
            }
        }
    }
}
