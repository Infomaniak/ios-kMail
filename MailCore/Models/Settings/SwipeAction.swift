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

    public typealias SwipeActionKeyPath = ReferenceWritableKeyPath<UserDefaults, SwipeAction>

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

    public var keyPath: SwipeActionKeyPath {
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

    public var excludedKeyPaths: [SwipeActionKeyPath] {
        switch self {
        case .leading:
            return [\.swipeFullLeading]
        case .fullLeading:
            return [\.swipeLeading]
        case .trailing:
            return [\.swipeFullTrailing]
        case .fullTrailing:
            return [\.swipeTrailing]
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
    case quickAction
    case moveToInbox
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
        case .quickAction:
            return MailResourcesStrings.Localizable.settingsSwipeActionQuickActionsMenu
        case .moveToInbox:
            return MailResourcesStrings.Localizable.actionMoveToInbox
        case .none:
            return MailResourcesStrings.Localizable.settingsSwipeActionNone
        }
    }

    public var matomoName: String {
        switch self {
        case .readUnread:
            return "markAsSeen"
        case .postPone:
            return "postpone"
        case .quickAction:
            return "quickActions"
        default:
            return rawValue
        }
    }

    public var matomoSettingsName: String {
        return "\(matomoName)Swipe"
    }

    public var isDestructive: Bool {
        switch self {
        case .delete, .archive, .spam, .moveToInbox:
            return true
        case .move, .readUnread, .postPone, .favorite, .quickAction, .none:
            return false
        }
    }

    public var isCustomizable: Bool {
        if self == .moveToInbox {
            return false
        }
        return true
    }

    public var isComingLater: Bool {
        if self == .postPone {
            return true
        }
        return false
    }

    public var image: Image? {
        return nil
    }

    public func icon(from thread: Thread? = nil) -> Image? {
        var resource: MailResourcesImages? {
            switch self {
            case .delete:
                return MailResourcesAsset.bin
            case .archive:
                return MailResourcesAsset.archives
            case .readUnread:
                if thread?.unseenMessages == 0 {
                    return MailResourcesAsset.envelope
                }
                return MailResourcesAsset.envelopeOpen
            case .move:
                return MailResourcesAsset.emailActionSend
            case .favorite:
                if thread?.flagged == true {
                    return MailResourcesAsset.unstar
                }
                return MailResourcesAsset.star
            case .postPone:
                return MailResourcesAsset.waitingMessage
            case .spam:
                return MailResourcesAsset.spam
            case .quickAction:
                return MailResourcesAsset.navigationMenu
            case .moveToInbox:
                return MailResourcesAsset.drawer
            case .none:
                return nil
            }
        }

        guard let resource else { return nil }
        return resource.swiftUIImage
    }

    public var swipeTint: Color? {
        let resource: MailResourcesColors?
        switch self {
        case .delete:
            resource = MailResourcesAsset.swipeDeleteColor
        case .archive:
            resource = MailResourcesAsset.swipeArchiveColor
        case .readUnread:
            resource = MailResourcesAsset.swipeReadColor
        case .move:
            resource = MailResourcesAsset.swipeMoveColor
        case .favorite:
            resource = MailResourcesAsset.swipeFavoriteColor
        case .postPone:
            resource = MailResourcesAsset.swipePostponeColor
        case .spam:
            resource = MailResourcesAsset.swipeSpamColor
        case .quickAction:
            resource = MailResourcesAsset.swipeQuickActionColor
        case .moveToInbox:
            resource = MailResourcesAsset.grayActionColor
        case .none:
            resource = nil
        }

        return resource?.swiftUIColor
    }

    public func fallback(for thread: Thread) -> Self? {
        switch self {
        case .archive:
            guard thread.folder?.role == .archive else { return nil }
            return .moveToInbox
        case .spam:
            guard thread.folder?.role == .spam else { return nil }
            return .moveToInbox
        case .delete, .favorite, .move, .readUnread, .postPone, .quickAction, .moveToInbox, .none:
            return nil
        }
    }
}
