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

import Foundation
import InfomaniakBugTracker
import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import InfomaniakLogin
import InfomaniakNotifications
import MailCore

private let realmRootPath = "mailboxes"
private let appGroupIdentifier = "group.com.infomaniak.mail"

extension Array where Element == Factory {
    func registerFactoriesInDI() {
        forEach { SimpleResolver.sharedResolver.store(factory: $0) }
    }
}

/// Something that prepares the application Dependency Injection
enum ApplicationAssembly {
    static func setupDI() {
        // Setup main servicies
        setupMainServices()

        // Setup proxy types necessary for the App code to work in Extension mode
        setupProxyTypes()
    }

    private static func setupMainServices() {
        let factories = [
            Factory(type: InfomaniakNetworkLoginable.self) { _, _ in
                InfomaniakNetworkLogin(clientId: MailApiFetcher.clientId)
            },
            Factory(type: InfomaniakLoginable.self) { _, _ in
                InfomaniakLogin(clientId: MailApiFetcher.clientId)
            },
            Factory(type: KeychainHelper.self) { _, _ in
                KeychainHelper(accessGroup: AccountManager.accessGroup)
            },
            Factory(type: InfomaniakNotifications.self) { _, _ in
                InfomaniakNotifications(appGroup: AccountManager.appGroup)
            },
            Factory(type: AppLockHelper.self) { _, _ in
                AppLockHelper()
            },
            Factory(type: BugTracker.self) { _, _ in
                BugTracker(info: BugTrackerInfo(project: "app-mobile-mail", gitHubRepoName: "ios-mail", appReleaseType: .beta))
            },
            Factory(type: MatomoUtils.self) { _, _ in
                MatomoUtils(siteId: Constants.matomoId, baseURL: URLConstants.matomo.url)
            },
            Factory(type: SnackBarAvoider.self) { _, _ in
                SnackBarAvoider()
            },
            Factory(type: DraftManager.self) { _, _ in
                DraftManager()
            },
            Factory(type: AccountManager.self) { _, _ in
                AccountManager()
            },
            Factory(type: SnackBarPresentable.self) { _, _ in
                SnackBarPresenter()
            },
            Factory(type: MessagePresentable.self) { _, _ in
                MessagePresenter()
            },
            Factory(type: ApplicationStatable.self) { _, _ in
                ApplicationState()
            },
            Factory(type: UserActivityController.self) { _, _ in
                UserActivityController()
            },
            Factory(type: PlatformDetectable.self) { _, _ in
                PlatformDetector()
            },
            Factory(type: AppGroupPathProvidable.self) { _, _ in
                guard let provider = AppGroupPathProvider(
                    realmRootPath: realmRootPath,
                    appGroupIdentifier: appGroupIdentifier
                ) else {
                    fatalError("could not safely init AppGroupPathProvider")
                }

                return provider
            },
            Factory(type: TokenStore.self) { _, _ in
                TokenStore()
            }
        ]

        factories.registerFactoriesInDI()
    }

    private static func setupProxyTypes() {
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

        factories.registerFactoriesInDI()
    }
}

/// Something that loads the DI on init
public struct EarlyDIHook {
    public init() {
        // setup DI ASAP
        ApplicationAssembly.setupDI()
    }
}
