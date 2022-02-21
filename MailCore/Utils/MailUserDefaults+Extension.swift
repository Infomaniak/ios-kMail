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

extension UserDefaults.Keys {
    static let currentMailboxId = UserDefaults.Keys(rawValue: "currentMailboxId")
    static let currentMailUserId = UserDefaults.Keys(rawValue: "currentMailUserId")
    static let notificationsEnabled = UserDefaults.Keys(rawValue: "notificationsEnabled")
}

public extension UserDefaults {
    static let shared = UserDefaults(suiteName: AccountManager.appGroup)!

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
}
