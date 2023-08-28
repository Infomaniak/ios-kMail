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

/// Something that prepares the extension Dependency Injection
enum NotificationServiceAssembly {
    static func setupDI() {
        // Setup main servicies
        setupMainServices()
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
            Factory(type: DraftManager.self) { _, _ in
                DraftManager()
            },
            Factory(type: AccountManager.self) { _, _ in
                AccountManager()
            },
            Factory(type: SnackBarPresentable.self) { _, _ in
                SnackBarPresenter()
            },
            Factory(type: UserAlertDisplayable.self) { _, _ in
                UserAlertDisplayer()
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
            },
            Factory(type: IKSnackBarAvoider.self) { _, _ in
                IKSnackBarAvoider()
            }
        ]

        factories.registerFactoriesInDI()
    }
}

/// Something that loads the DI on init
public struct EarlyDIHook {
    public init() {
        ApiFetcher.decoder.dateDecodingStrategy = .iso8601

        // setup DI ASAP
        NotificationServiceAssembly.setupDI()
    }
}
