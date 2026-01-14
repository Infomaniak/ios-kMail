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

import DeviceAssociation
import Foundation
import InAppTwoFactorAuthentication
import InfomaniakBugTracker
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakDI
import InfomaniakLogin
import InfomaniakNotifications
import MyKSuite
import Nuke
import OSLog

extension [Factory] {
    func registerFactoriesInDI() {
        forEach { SimpleResolver.sharedResolver.store(factory: $0) }
    }
}

/// Each target should subclass `TargetAssembly` and override `getTargetServices` to provide additional, target related, services.
open class TargetAssembly {
    private static let apiEnvironment: ApiEnvironment = .prod
    private static let realmRootPath = "mailboxes"
    private static let appGroupIdentifier = "group.\(bundleId)"
    private static let sharedAppGroupName = "group.com.infomaniak"

    public static let bundleId = "com.infomaniak.mail"
    public static let loginConfig = InfomaniakLogin.Config(
        clientId: "E90BC22D-67A8-452C-BE93-28DA33588CA4",
        loginURL: URL(string: "https://\(apiEnvironment.loginHost)/")!,
        accessType: nil
    )

    public init() {
        // Setup debug stack early
        Logging.initLogging()
        ApiEnvironment.current = Self.apiEnvironment

        // setup DI ASAP
        Self.setupDI()

        SVGImageDecoder.register()
    }

    open class func getCommonServices() -> [Factory] {
        return [
            Factory(type: MailboxInfosManager.self) { _, _ in
                MailboxInfosManager()
            },
            Factory(type: InfomaniakNetworkLoginable.self) { _, _ in
                InfomaniakNetworkLogin(config: loginConfig)
            },
            Factory(type: InfomaniakLoginable.self) { _, _ in
                InfomaniakLogin(config: loginConfig)
            },
            Factory(type: KeychainHelper.self) { _, _ in
                KeychainHelper(accessGroup: AccountManager.accessGroup)
            },
            Factory(type: InfomaniakNotifications.self) { _, _ in
                InfomaniakNotifications(appGroup: AccountManager.appGroup)
            },
            Factory(type: FeatureFlagsManageable.self) { _, _ in
                FeatureFlagsManager()
            },
            Factory(type: FeatureAvailableProvider.self) { _, _ in
                FeatureAvailableService()
            },
            Factory(type: BugTracker.self) { _, _ in
                BugTracker(info: BugTrackerInfo(project: "app-mobile-mail"))
            },
            Factory(type: MatomoUtils.self) { _, _ in
                let matomo = MatomoUtils(siteId: Constants.matomoId, baseURL: URLConstants.matomo.url)
                #if DEBUG
                matomo.optOut(true)
                #endif
                return matomo
            },
            Factory(type: IKSnackBarAvoider.self) { _, _ in
                IKSnackBarAvoider()
            },
            Factory(type: DraftManager.self) { _, _ in
                DraftManager()
            },
            Factory(type: AccountManager.self) { _, _ in
                AccountManager()
            },
            Factory(type: IKSnackBarPresentable.self) { _, _ in
                SnackBarPresenter()
            },
            Factory(type: UserAlertDisplayable.self) { _, _ in
                UserAlertDisplayer()
            },
            Factory(type: PlatformDetectable.self) { _, _ in
                PlatformDetector()
            },
            Factory(type: RealmManageable.self) { _, _ in
                RealmManager()
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
            Factory(type: DeviceManagerable.self) { _, _ in
                let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String? ?? "x.x"
                return DeviceManager(appGroupIdentifier: sharedAppGroupName,
                                     appMarketingVersion: version,
                                     capabilities: [.twoFactorAuthenticationChallengeApproval])
            },
            Factory(type: TokenStore.self) { _, _ in
                TokenStore()
            },
            Factory(type: LocalContactsHelpable.self) { _, _ in
                LocalContactsHelper()
            },
            Factory(type: ContactCache.self) { _, _ in
                let contactCache = ContactCache()
                if Bundle.main.isExtension {
                    // Limit the cache size in extension mode, not strictly needed, but coherent.
                    contactCache.countLimit = Constants.contactCacheExtensionMaxCount
                }
                return contactCache
            },
            Factory(type: MyKSuiteStore.self) { _, _ in
                MyKSuiteStore()
            },
            Factory(type: AttachmentCacheHelper.self) { _, _ in
                AttachmentCacheHelper(pipeline: ImagePipeline(configuration: .withDataCache))
            },
            Factory(type: MainViewStateStore.self) { _, _ in
                MainViewStateStore()
            },
            Factory(type: ServerStatusManager.self) { _, _ in
                ServerStatusManager()
            }
        ]
    }

    open class func getTargetServices() -> [Factory] {
        Logger.general.error("targetServices is not implemented in subclass ? Did you forget to override ?")
        return []
    }

    public static func setupDI() {
        (getCommonServices() + getTargetServices()).registerFactoriesInDI()
    }
}
