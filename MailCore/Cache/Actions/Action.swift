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
import MailResources
import SwiftUI

public struct Action: Identifiable, Hashable, Equatable {
    public let id: String
    public let title: String
    public let shortTitle: String?
    public let iconName: String
    public var icon: Image {
        return Image(iconName, bundle: MailResourcesResources.bundle)
    }

    public var accessibilityIdentifier: String {
        return "action/\(id)"
    }

    public let tintColorName: String?
    public var tintColor: Color? {
        guard let tintColorName else { return nil }
        return Color(tintColorName, bundle: MailResourcesResources.bundle)
    }

    public let isDestructive: Bool

    public let matomoName: String

    init(
        id: String,
        title: String,
        shortTitle: String? = nil,
        iconResource: MailResourcesImages,
        tintColorResource: MailResourcesColors? = nil,
        isDestructive: Bool = false,
        matomoName: String
    ) {
        self.id = id
        self.title = title
        self.shortTitle = shortTitle
        iconName = iconResource.name
        tintColorName = tintColorResource?.name
        self.isDestructive = isDestructive
        self.matomoName = matomoName
    }

    public func inverseActionIfNeeded(for thread: Thread) -> Self {
        switch self {
        case .archive:
            if thread.folder?.role == .archive {
                return .moveToInbox
            }
        case .spam:
            if thread.folder?.role == .spam {
                return .moveToInbox
            }
        case .markAsRead:
            if !thread.hasUnseenMessages {
                return .markAsUnread
            }
        case .star:
            if thread.flagged {
                return .unstar
            }
        default:
            return self
        }

        return self
    }
}

extension Action: SettingsOptionEnum {
    public var image: Image? {
        return nil
    }

    public var hint: String? {
        return nil
    }
}
