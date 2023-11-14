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
struct MailApp: App {
    /// Making sure the DI is registered at a very early stage of the app launch.
    private let dependencyInjectionHook = EarlyDIHook()

    @LazyInjectService private var appLockHelper: AppLockHelper
    @LazyInjectService private var accountManager: AccountManager
    @LazyInjectService private var appLaunchCounter: AppLaunchCounter

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(UserDefaults.shared.key(.accentColor), store: .shared) private var accentColor = DefaultPreferences.accentColor
    @AppStorage(UserDefaults.shared.key(.theme), store: .shared) private var theme = DefaultPreferences.theme

    @StateObject private var navigationState = NavigationState()
    @StateObject private var reviewManager = ReviewManager()

    init() {
        DDLogInfo("Application starting in foreground ? \(UIApplication.shared.applicationState != .background)")
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(navigationState)
                .environmentObject(reviewManager)
                .onAppear {
                    updateUI(accent: accentColor, theme: theme)
                }
                .onChange(of: theme) { newTheme in
                    updateUI(accent: accentColor, theme: newTheme)
                }
                .onChange(of: accentColor) { newAccentColor in
                    updateUI(accent: newAccentColor, theme: theme)
                }
                .onChange(of: scenePhase) { newScenePhase in
                    switch newScenePhase {
                    case .active:
                        appLaunchCounter.increase()
                        refreshCacheData()
                        navigationState.transitionToLockViewIfNeeded()
                        UserDefaults.shared.openingUntilReview -= 1
                    case .background:
                        if UserDefaults.shared.isAppLockEnabled && navigationState.rootViewState != .appLocked {
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
            #if targetEnvironment(macCatalyst)
                .introspect(.window, on: .iOS(.v16, .v17)) { window in
                    if let titlebar = window.windowScene?.titlebar {
                        titlebar.titleVisibility = .hidden
                        titlebar.toolbar = nil
                    }
                }
            #endif
        }
        .defaultAppStorage(.shared)
    }

    func updateUI(accent: AccentColor, theme: Theme) {
        let allWindows = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows)
        for window in allWindows {
            window.overrideUserInterfaceStyle = theme.interfaceStyle
            window.tintColor = accent.primary.color
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

                try await accountManager.currentContactManager?.refreshContactsAndAddressBooks()
            } catch {
                DDLogError("Error while updating user account: \(error)")
            }
        }
    }
}
