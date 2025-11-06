/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import Foundation
import InAppTwoFactorAuthentication
import InfomaniakBugTracker
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakDI
import InfomaniakLogin
import InfomaniakNotifications
import InterAppLogin
import MailCore

open class CommonAppAndShareTargetAssembly: TargetAssembly {
    override open class func getTargetServices() -> [Factory] {
        return [
            Factory(type: CacheManageable.self) { _, _ in
                CacheManager()
            },
            Factory(type: OrientationManageable.self) { _, _ in
                OrientationManager()
            },
            Factory(type: RemoteNotificationRegistrable.self) { _, _ in
                RemoteNotificationRegistrer()
            },
            Factory(type: MessageActionHandlable.self) { _, _ in
                MessageActionHandler()
            },
            Factory(type: ApplicationStatable.self) { _, _ in
                ApplicationState()
            },
            Factory(type: URLOpenable.self) { _, _ in
                URLOpener()
            },
            Factory(type: ReviewManageable.self) { _, _ in
                ReviewManager(userDefaults: UserDefaults.shared)
            }
        ]
    }
}

// periphery:ignore - Used by DI
class MailTargetAssembly: CommonAppAndShareTargetAssembly {
    override class func getTargetServices() -> [Factory] {
        return super.getTargetServices() + [
            Factory(type: InAppTwoFactorAuthenticationManagerable.self) { _, _ in
                InAppTwoFactorAuthenticationManager()
            },
            Factory(type: RefreshAppBackgroundTask.self) { _, _ in
                RefreshAppBackgroundTask()
            },
            Factory(type: AppLaunchCounter.self) { _, _ in
                AppLaunchCounter()
            },
            Factory(type: UserActivityController.self) { _, _ in
                UserActivityController()
            },
            Factory(type: AppLockHelper.self) { _, _ in
                AppLockHelper()
            },
            Factory(type: ConfigWebServer.self) { _, _ in
                ConfigWebServer()
            },
            Factory(type: NotificationActionsRegistrable.self) { _, _ in
                NotificationActionsRegistrer()
            },
            Factory(type: ConnectedAccountManagerable.self) { _, _ in
                ConnectedAccountManager(currentAppKeychainIdentifier: AppIdentifierBuilder.mailKeychainIdentifier)
            }
        ]
    }
}
