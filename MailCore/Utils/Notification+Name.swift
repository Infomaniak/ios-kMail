/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

public extension Notification.Name {
    static let closeDrawer = Notification.Name("closeDrawer")
    static let dismissMoveSheet = Notification.Name(rawValue: "sheetViewDismiss")
    static let updateComposeMessageBody = Notification.Name(rawValue: "updateComposeMessageBody")
    static let openNotificationSettings = Notification.Name(rawValue: "openNotificationSettings")
    static let printNotification = Notification.Name(rawValue: "printNotification")
    static let userPerformedHomeScreenShortcut = Notification.Name(rawValue: "userPerformedHomeScreenShortcut")
}
