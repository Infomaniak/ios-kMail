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

public enum DefaultPreferences {
    public static let notificationsEnabled = true
    public static let appLock = false
    public static let threadDensity = ThreadDensity.large
    public static let externalContent = ExternalContent.always
    public static let theme = Theme.system
    public static let accentColor = AccentColor.pink
    public static let swipeLeading = SwipeAction.none
    public static let swipeFullLeading = SwipeAction.readUnread
    public static let swipeTrailing = SwipeAction.quickAction
    public static let swipeFullTrailing = SwipeAction.delete
    public static let cancelDelay = CancelDelay.seconds10
    public static let forwardMode = ForwardMode.inline
    public static let acknowledgement = false
    public static let includeOriginalInReply = false
}
