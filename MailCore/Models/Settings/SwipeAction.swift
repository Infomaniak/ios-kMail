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
import MailResources
import SwiftUI

public enum SwipeType: String, CaseIterable {
    case shortRight
    case longRight
    case shortLeft
    case longLeft

    public var title: String {
        switch self {
        case .shortRight:
            return MailResourcesStrings.settingsSwipeShortRight
        case .longRight:
            return MailResourcesStrings.settingsSwipeLongRight
        case .shortLeft:
            return MailResourcesStrings.settingsSwipeShortLeft
        case .longLeft:
            return MailResourcesStrings.settingsSwipeLongLeft
        }
    }

    public var setting: SwipeAction {
        get {
            switch self {
            case .shortRight:
                return UserDefaults.shared.swipeShortRight
            case .longRight:
                return UserDefaults.shared.swipeLongRight
            case .shortLeft:
                return UserDefaults.shared.swipeShortLeft
            case .longLeft:
                return UserDefaults.shared.swipeLongLeft
            }
        }
        set {
            switch self {
            case .shortRight:
                UserDefaults.shared.swipeShortRight = newValue
            case .longRight:
                UserDefaults.shared.swipeLongRight = newValue
            case .shortLeft:
                UserDefaults.shared.swipeShortLeft = newValue
            case .longLeft:
                UserDefaults.shared.swipeLongLeft = newValue
            }
        }
    }
}

public enum SwipeAction: String, CaseIterable, SettingsOptionEnum {
    case delete
    case archive
    case readUnread
    case move
    case report
    case spam
    case readAndAchive
    case quickAction
    case none

    public var title: String {
        switch self {
        case .delete:
            return MailResourcesStrings.actionDelete
        case .archive:
            return MailResourcesStrings.actionArchive
        case .readUnread:
            return MailResourcesStrings.settingsSwipeActionReadUnread
        case .move:
            return MailResourcesStrings.actionMove
        case .report:
            return MailResourcesStrings.actionPostpone
        case .spam:
            return MailResourcesStrings.actionSpam
        case .readAndAchive:
            return MailResourcesStrings.settingsSwipeActionReadAndArchive
        case .quickAction:
            return MailResourcesStrings.settingsSwipeActionQuickActionsMenu
        case .none:
            return MailResourcesStrings.settingsSwipeActionNone
        }
    }

    public var image: Image? {
        return nil
    }

    public var swipeIcon: Image? {
        switch self {
        case .delete:
            return Image(uiImage: MailResourcesAsset.bin.image)
        case .archive:
            return Image(uiImage: MailResourcesAsset.archives.image)
        case .readUnread:
            return Image(uiImage: MailResourcesAsset.envelopeOpen.image)
        case .move:
            return Image(uiImage: MailResourcesAsset.emailActionSend21.image)
        case .report:
//            return Image(uiImage: MailResourcesAsset.)
            return nil
        case .spam:
            return Image(uiImage: MailResourcesAsset.spam.image)
        case .readAndAchive:
//            return Image(uiImage: MailResourcesAsset.)
            return nil
        case .quickAction:
            return Image(uiImage: MailResourcesAsset.plusActions.image)
        case .none:
            return nil
        }
    }

    public var swipeTint: UIColor? {
        switch self {
        case .delete:
            return MailResourcesAsset.destructiveActionColor.color
        case .archive:
            return .blue
        case .readUnread:
            return MailResourcesAsset.unreadActionColor.color
        case .move:
            return .blue
        case .report:
            return .blue
        case .spam:
            return .blue
        case .readAndAchive:
            return .blue
        case .quickAction:
            return MailResourcesAsset.menuActionColor.color
        case .none:
            return nil
        }
    }
}
