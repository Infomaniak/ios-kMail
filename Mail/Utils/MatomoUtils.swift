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
import MatomoTracker
import MailCore

class MatomoUtils {
    static let shared: MatomoTracker = {
        let tracker = MatomoTracker(siteId: "9", baseURL: URLConstants.matomo.url)
        tracker.userId = String(AccountManager.instance.currentUserId)
        return tracker
    }()

    // Enable or disable Matomo tracking
    static let isEnabled = true

    enum Views: String {
        case shareAndRights, save, search, uploadQueue, preview, menu, settings, store, security

        var displayName: String {
            return rawValue.capitalized
        }
    }

    enum EventCategory: String {
        case newElement, fileListFileAction, picturesFileAction, fileInfo, shareAndRights, colorFolder, categories, search,
             fileList, comment, drive, account, settings, photoSync, home, displayList, inApp, trash,
             dropbox, preview, mediaPlayer
    }

    enum UserAction: String {
        case click, input
    }

    static func connectUser() {
        guard isEnabled else { return }
        shared.userId = String(AccountManager.instance.currentUserId)
    }

    static func track(view: [String]) {
        guard isEnabled else { return }
        shared.track(view: view)
    }

    static func track(eventWithCategory category: EventCategory, action: UserAction = .click, name: String, value: Float? = nil) {
        guard isEnabled else { return }
        shared.track(eventWithCategory: category.rawValue, action: action.rawValue, name: name, value: value)
    }

    static func track(eventWithCategory category: EventCategory, action: UserAction = .click, name: String, value: Bool) {
        track(eventWithCategory: category, action: action, name: name, value: value ? 1.0 : 0.0)
    }
}
