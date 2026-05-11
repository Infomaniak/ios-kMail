/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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

public enum MessageBanner: Equatable, Identifiable, Hashable {
    public var id: Int {
        return hashValue
    }

    public var matomoName: String {
        switch self {
        case .schedule:
            return "modifySchedule"
        case .spam:
            return "spam"
        case .displayContent:
            return "displayContent"
        case .encrypted:
            return "encryption"
        case .unsubscribeLink:
            return "unsubscribeLink"
        case .acknowledge:
            return "acknowledge"
        }
    }

    case schedule(scheduleDate: Date, draftResource: String)
    case spam(spamType: SpamHeaderType)
    case displayContent
    case encrypted
    case unsubscribeLink
    case acknowledge

    public static func == (lhs: MessageBanner, rhs: MessageBanner) -> Bool {
        switch (lhs, rhs) {
        case (.schedule(let date1, let resource1), .schedule(let date2, let resource2)):
            return date1 == date2 && resource1 == resource2
        case (.spam(let type1), .spam(let type2)):
            return type1 == type2
        case (.displayContent, .displayContent):
            return true
        case (.encrypted, .encrypted):
            return true
        case (.unsubscribeLink, .unsubscribeLink):
            return true
        case (.acknowledge, .acknowledge):
            return true
        default:
            return false
        }
    }
}

public extension [MessageBanner] {
    func shouldShowBottomSeparator(for messageBanner: MessageBanner) -> Bool {
        switch messageBanner {
        case .schedule:
            return count == 1
        case .spam:
            return !(contains(.displayContent) || contains(.encrypted))
        case .displayContent:
            return !contains(.encrypted)
        case .unsubscribeLink:
            return true
        case .acknowledge:
            return true
        default:
            return false
        }
    }
}
