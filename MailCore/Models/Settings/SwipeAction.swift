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
    case leading
    case fullLeading
    case trailing
    case fullTrailing

    public var title: String {
        switch self {
        case .leading:
            return MailResourcesStrings.Localizable.settingsSwipeShortRight
        case .fullLeading:
            return MailResourcesStrings.Localizable.settingsSwipeLongRight
        case .trailing:
            return MailResourcesStrings.Localizable.settingsSwipeShortLeft
        case .fullTrailing:
            return MailResourcesStrings.Localizable.settingsSwipeLongLeft
        }
    }

    public var keyPath: ReferenceWritableKeyPath<UserDefaults, SwipeAction> {
        switch self {
        case .leading:
            return \.swipeLeading
        case .fullLeading:
            return \.swipeFullLeading
        case .trailing:
            return \.swipeTrailing
        case .fullTrailing:
            return \.swipeFullTrailing
        }
    }
}

public enum SwipeAction: String, CaseIterable, SettingsOptionEnum {
    case delete
    case archive
    case readUnread
    case move
    case favorite
    case postPone
    case spam
    case readAndArchive
    case quickAction
    case none

    public var title: String {
        switch self {
        case .delete:
            return MailResourcesStrings.Localizable.actionDelete
        case .archive:
            return MailResourcesStrings.Localizable.actionArchive
        case .readUnread:
            return MailResourcesStrings.Localizable.settingsSwipeActionReadUnread
        case .move:
            return MailResourcesStrings.Localizable.actionMove
        case .favorite:
            return MailResourcesStrings.Localizable.favoritesFolder
        case .postPone:
            return MailResourcesStrings.Localizable.actionPostpone
        case .spam:
            return MailResourcesStrings.Localizable.actionSpam
        case .readAndArchive:
            return MailResourcesStrings.Localizable.settingsSwipeActionReadAndArchive
        case .quickAction:
            return MailResourcesStrings.Localizable.settingsSwipeActionQuickActionsMenu
        case .none:
            return MailResourcesStrings.Localizable.settingsSwipeActionNone
        }
    }

    public var isDestructive: Bool {
        switch self {
        case .delete, .archive, .spam, .readAndArchive:
            return true
        case .move, .readUnread, .postPone, .favorite, .quickAction, .none:
            return false
        }
    }

    public var image: Image? {
        return nil
    }

    public var swipeIcon: Image? {
        let resource: MailResourcesImages?
        switch self {
        case .delete:
            resource = MailResourcesAsset.bin
        case .archive:
            resource = MailResourcesAsset.archives
        case .readUnread:
            resource = MailResourcesAsset.envelopeOpen
        case .move:
            resource = MailResourcesAsset.emailActionSend
        case .favorite:
            resource = MailResourcesAsset.star
        case .postPone:
            resource = MailResourcesAsset.waitingMessage
        case .spam:
            resource = MailResourcesAsset.spam
        case .readAndArchive:
            resource = MailResourcesAsset.drawer
        case .quickAction:
            resource = MailResourcesAsset.navigationMenu
        case .none:
            resource = nil
        }

        if let resource = resource {
            return Image(resource.name)
        } else {
            return nil
        }
    }

    public var swipeTint: Color? {
        let resource: MailResourcesColors?
        switch self {
        case .delete:
            resource = MailResourcesAsset.redActionColor
        case .archive:
            resource = MailResourcesAsset.purpleActionColor
        case .readUnread:
            resource = MailResourcesAsset.darkBlueActionColor
        case .move:
            resource = MailResourcesAsset.greenActionColor
        case .favorite:
            resource = MailResourcesAsset.yellowActionColor
        case .postPone:
            resource = MailResourcesAsset.lightBlueActionColor
        case .spam:
            resource = MailResourcesAsset.warningColor
        case .readAndArchive:
            resource = MailResourcesAsset.darkPurpleActionColor
        case .quickAction:
            resource = MailResourcesAsset.menuActionColor
        case .none:
            resource = nil
        }

        return resource?.swiftUiColor
    }
}
