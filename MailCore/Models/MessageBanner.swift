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

public enum MessageBanner: Equatable {
    case schedule(scheduleDate: Date, draftResource: String)
    case spam(spamType: SpamHeaderType)
    case displayContent
    case encrypted

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
        default:
            return false
        }
    }
}

public extension [MessageBanner] {
    var spamType: SpamHeaderType? {
        if case .spam(let spamType) = first(where: {
            if case .spam = $0 { return true }
            return false
        }) {
            return spamType
        }
        return nil
    }

    var scheduleData: (scheduleDate: Date, draftResource: String)? {
        if case .schedule(let scheduleDate, let draftResource) = first(where: {
            if case .schedule = $0 { return true }
            return false
        }) {
            return (scheduleDate: scheduleDate, draftResource: draftResource)
        }
        return nil
    }

    func isLast(messageBanner: MessageBanner) -> Bool {
        switch messageBanner {
        case .schedule:
            return count == 1
        case .spam:
            return !(contains(.displayContent) || contains(.encrypted))
        case .displayContent:
            return !contains(.encrypted)
        default:
            return false
        }
    }
}
