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

import AppIntents
import InfomaniakBugTracker
import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import InfomaniakLogin
import InfomaniakNotifications
import MailCore

private let realmRootPath = "mailboxes"
private let appGroupIdentifier = "group.com.infomaniak.mail"

@main
struct MailAppIntentsExtension: AppIntentsExtension {
    init() {
        let sharedServices = [
            Factory(type: InfomaniakNetworkLoginable.self) { _, _ in
                InfomaniakNetworkLogin(clientId: MailApiFetcher.clientId)
            },
            Factory(type: InfomaniakLoginable.self) { _, _ in
                InfomaniakLogin(clientId: MailApiFetcher.clientId)
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
            Factory(type: MailboxInfosManager.self) { _, _ in
                MailboxInfosManager()
            },
            Factory(type: KeychainHelper.self) { _, _ in
                KeychainHelper(accessGroup: AccountManager.accessGroup)
            },
            Factory(type: AccountManager.self) { _, _ in
                AccountManager()
            },
            Factory(type: TokenStore.self) { _, _ in
                TokenStore()
            },
            Factory(type: InfomaniakNotifications.self) { _, _ in
                InfomaniakNotifications(appGroup: AccountManager.appGroup)
            },
            Factory(type: FeatureFlagsManageable.self) { _, _ in
                FeatureFlagsManager()
            },
            Factory(type: BugTracker.self) { _, _ in
                BugTracker(info: BugTrackerInfo(project: "app-mobile-mail", gitHubRepoName: "ios-mail", appReleaseType: .beta))
            },
            Factory(type: MatomoUtils.self) { _, _ in
                MatomoUtils(siteId: Constants.matomoId, baseURL: URLConstants.matomo.url)
            },
            Factory(type: RealmManageable.self) { _, _ in
                RealmManager()
            },
            Factory(type: FeatureFlagsManageable.self) { _, _ in
                FeatureFlagsManager()
            }
        ]

        sharedServices.forEach { SimpleResolver.sharedResolver.store(factory: $0) }
    }
}
