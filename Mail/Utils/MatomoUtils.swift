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
import MailCore
import MatomoTracker

class MatomoUtils {
    static let shared: MatomoTracker = {
        let tracker = MatomoTracker(siteId: "9", baseURL: URLConstants.matomo.url)
        #if DEBUG
        tracker.isOptedOut = true
        #endif
        tracker.userId = String(AccountManager.instance.currentUserId)
        return tracker
    }()

    static func connectUser() {
        shared.userId = String(AccountManager.instance.currentUserId)
    }

    static func track(view: [String]) {
        shared.track(view: view)
    }
}
