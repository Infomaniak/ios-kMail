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
import SwiftUI

public protocol SettingsOptionEnum {
    var title: String { get }
    var image: Image? { get }
}

public extension UserDefaults.Keys {
    static let currentMailboxId = UserDefaults.Keys(rawValue: "currentMailboxId")
    static let currentMailUserId = UserDefaults.Keys(rawValue: "currentMailUserId")
    static let notificationsEnabled = UserDefaults.Keys(rawValue: "notificationsEnabled")
    static let appLock = UserDefaults.Keys(rawValue: "appLock")
    static let threadDensity = UserDefaults.Keys(rawValue: "threadDensity")
    static let externalContent = UserDefaults.Keys(rawValue: "externalContent")
    static let theme = UserDefaults.Keys(rawValue: "theme")
    static let accentColor = UserDefaults.Keys(rawValue: "accentColor")
    static let swipeShortRight = UserDefaults.Keys(rawValue: "swipeShortRight")
    static let swipeLongRight = UserDefaults.Keys(rawValue: "swipeLongRight")
    static let swipeShortLeft = UserDefaults.Keys(rawValue: "swipeShortLeft")
    static let swipeLongLeft = UserDefaults.Keys(rawValue: "swipeLongLeft")
    static let cancelDelay = UserDefaults.Keys(rawValue: "cancelDelay")
    static let forwardMode = UserDefaults.Keys(rawValue: "forwardMode")
    static let acknowledgement = UserDefaults.Keys(rawValue: "acknowledgement")
    static let includeOriginalInReply = UserDefaults.Keys(rawValue: "includeOriginalInReply")
}

public extension UserDefaults {
    static let shared = UserDefaults(suiteName: AccountManager.appGroup)!

    func initSettings() {
        UserDefaults.shared.register(defaults: [
            key(.notificationsEnabled): true,
            key(.appLock): false,
            key(.threadDensity): ThreadDensity.normal.rawValue,
            key(.externalContent): ExternalContent.always.rawValue,
            key(.theme): Theme.system.rawValue,
            key(.accentColor): AccentColor.pink.rawValue,
            key(.swipeShortRight): Constants.defaultSwipeShortRight.rawValue,
            key(.swipeLongRight): Constants.defaultSwipeLongRight.rawValue,
            key(.swipeShortLeft): Constants.defaultSwipeShortLeft.rawValue,
            key(.swipeLongLeft): Constants.defaultSwipeLongLeft.rawValue,
            key(.cancelDelay): CancelDelay.seconds10.rawValue,
            key(.forwardMode): ForwardMode.inline.rawValue,
            key(.acknowledgement): false,
            key(.includeOriginalInReply): false
        ])
    }

    var currentMailboxId: Int {
        get {
            return integer(forKey: key(.currentMailboxId))
        }
        set {
            set(newValue, forKey: key(.currentMailboxId))
        }
    }

    var currentMailUserId: Int {
        get {
            return integer(forKey: key(.currentMailUserId))
        }
        set {
            set(newValue, forKey: key(.currentMailUserId))
        }
    }

    var isNotificationEnabled: Bool {
        get {
            if object(forKey: key(.notificationsEnabled)) == nil {
                set(true, forKey: key(.notificationsEnabled))
            }
            return bool(forKey: key(.notificationsEnabled))
        }
        set {
            set(newValue, forKey: key(.notificationsEnabled))
        }
    }

    var isAppLockEnabled: Bool {
        get {
            return bool(forKey: key(.appLock))
        }
        set {
            set(newValue, forKey: key(.appLock))
        }
    }

    var threadDensity: ThreadDensity {
        get {
            return ThreadDensity(rawValue: string(forKey: key(.threadDensity)) ?? "") ?? .normal
        }
        set {
            set(newValue.rawValue, forKey: key(.threadDensity))
        }
    }

    var displayExternalContent: ExternalContent {
        get {
            return ExternalContent(rawValue: string(forKey: key(.externalContent)) ?? "") ?? .always
        }
        set {
            set(newValue.rawValue, forKey: key(.externalContent))
        }
    }

    var theme: Theme {
        get {
            let defaultTheme = Theme.system
            guard let theme = string(forKey: key(.theme)) else {
                setValue(defaultTheme.rawValue, forKey: key(.theme))
                return defaultTheme
            }
            return Theme(rawValue: theme) ?? defaultTheme
        }
        set {
            setValue(newValue.rawValue, forKey: key(.theme))
        }
    }

    var accentColor: AccentColor {
        get {
            return AccentColor(rawValue: string(forKey: key(.accentColor)) ?? "") ?? .pink
        }
        set {
            setValue(newValue.rawValue, forKey: key(.accentColor))
        }
    }

    var swipeShortRight: SwipeAction {
        get {
            return SwipeAction(rawValue: string(forKey: key(.swipeShortRight)) ?? "") ?? Constants.defaultSwipeShortRight
        }
        set {
            set(newValue.rawValue, forKey: key(.swipeShortRight))
        }
    }

    var swipeLongRight: SwipeAction {
        get {
            return SwipeAction(rawValue: string(forKey: key(.swipeLongRight)) ?? "") ?? Constants.defaultSwipeLongRight
        }
        set {
            set(newValue.rawValue, forKey: key(.swipeLongRight))
        }
    }

    var swipeShortLeft: SwipeAction {
        get {
            return SwipeAction(rawValue: string(forKey: key(.swipeShortLeft)) ?? "") ?? Constants.defaultSwipeShortLeft
        }
        set {
            set(newValue.rawValue, forKey: key(.swipeShortLeft))
        }
    }

    var swipeLongLeft: SwipeAction {
        get {
            return SwipeAction(rawValue: string(forKey: key(.swipeLongLeft)) ?? "") ?? Constants.defaultSwipeLongLeft
        }
        set {
            set(newValue.rawValue, forKey: key(.swipeLongLeft))
        }
    }

    var cancelSendDelay: CancelDelay {
        get {
            return CancelDelay(rawValue: integer(forKey: key(.cancelDelay))) ?? .seconds10
        }
        set {
            set(newValue.rawValue, forKey: key(.cancelDelay))
        }
    }

    var forwardMode: ForwardMode {
        get {
            ForwardMode(rawValue: string(forKey: key(.forwardMode)) ?? "") ?? .inline
        }
        set {
            set(newValue.rawValue, forKey: key(.forwardMode))
        }
    }

    var includeOriginalInReply: Bool {
        get {
            return bool(forKey: key(.includeOriginalInReply))
        }
        set {
            set(newValue, forKey: key(.includeOriginalInReply))
        }
    }

    var acknowledgement: Bool {
        get {
            return bool(forKey: key(.acknowledgement))
        }
        set {
            set(newValue, forKey: key(.acknowledgement))
        }
    }
}
