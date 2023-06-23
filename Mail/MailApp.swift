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

public struct EarlyDIHook {
    public init() {
        // setup DI ASAP
        setupDI()
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

        SimpleResolver.sharedResolver.store(factory: networkLoginService)
        SimpleResolver.sharedResolver.store(factory: loginService)
        SimpleResolver.sharedResolver.store(factory: notificationService)
        SimpleResolver.sharedResolver.store(factory: keychainHelper)
        SimpleResolver.sharedResolver.store(factory: appLockHelper)
        SimpleResolver.sharedResolver.store(factory: bugTracker)
        SimpleResolver.sharedResolver.store(factory: matomoUtils)
        SimpleResolver.sharedResolver.store(factory: avoider)
    }
}

@main
struct MailApp: App {
    /// Making sure the DI is registered at a very early stage of the app launch.
    private let dependencyInjectionHook = EarlyDIHook()
    @LazyInjectService var appLockHelper: AppLockHelper

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor
    @AppStorage(UserDefaults.shared.key(.theme)) private var theme = DefaultPreferences.theme

    @StateObject private var navigationStore = NavigationStore()

    @ObservedObject private var accountManager = AccountManager.instance

    init() {
        Logging.initLogging()
        DDLogInfo("Application starting in foreground ? \(UIApplication.shared.applicationState != .background)")
        ApiFetcher.decoder.dateDecodingStrategy = .iso8601
    }

    var body: some Scene {
        WindowGroup {
            RootView(rootViewState: navigationStore.rootViewState)
                .environmentObject(navigationStore)
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
                        refreshCacheData()
                        if UserDefaults.shared.isAppLockEnabled
                            && appLockHelper.isAppLocked
                            && accountManager.currentAccount != nil {
                            navigationStore.transitionToRootViewDestination(.appLocked)
                        }
                    case .background:
                        if UserDefaults.shared.isAppLockEnabled && navigationStore.rootViewState != .appLocked {
                            appLockHelper.setTime()
                        }
                    case .inactive:
                        Task {
                            await NotificationsHelper.updateUnreadCountBadge()
                        }
                    @unknown default:
                        break
                    }
                }
                .onChange(of: accountManager.currentAccount) { _ in
                    refreshCacheData()
                }
                .onChange(of: accountManager.currentMailboxId) { _ in
                    if accountManager.currentAccount == nil {
                        navigationStore.transitionToRootViewDestination(.onboarding)
                    } else if navigationStore.rootViewState != .appLocked {
                        navigationStore.transitionToRootViewDestination(.mainView)
                    }
                }
        }
        .defaultAppStorage(.shared)
    }

    func updateUI(accent: AccentColor, theme: Theme) {
        let allWindows = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap { $0.windows }
        for window in allWindows {
            window.tintColor = accent.primary.color
            window.overrideUserInterfaceStyle = theme.interfaceStyle
        }
    }

    func refreshCacheData() {
        guard let currentAccount = AccountManager.instance.currentAccount else {
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
}
