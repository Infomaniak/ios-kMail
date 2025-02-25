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
import Sentry

public enum DeltaFlagsType: Sendable {
    case messages([MessageFlags])
    case snoozed([SnoozedFlags])
    case unknown

    public var flags: [DeltaFlags] {
        switch self {
        case .messages(let deltaFlags):
            return deltaFlags
        case .snoozed(let deltaFlags):
            return deltaFlags
        case .unknown:
            return []
        }
    }
}

public struct MessagesDelta: Decodable, Sendable {
    public let deletedShortUids: [String]
    public let addedShortUids: [String]
    public let updated: DeltaFlagsType
    public let cursor: String
    public let unreadCount: Int

    private enum CodingKeys: String, CodingKey {
        case deletedShortUids = "deleted"
        case addedShortUids = "added"
        case updated
        case cursor = "signature"
        case unreadCount
    }
}

public protocol DeltaFlags: Decodable, Sendable {
    var shortUid: String { get }
}

public struct MessageFlags: DeltaFlags {
    public let shortUid: String
    public let answered: Bool
    public let isFavorite: Bool
    public let forwarded: Bool
    public let scheduled: Bool
    public let seen: Bool

    private enum CodingKeys: String, CodingKey {
        case shortUid = "uid"
        case answered
        case isFavorite = "flagged"
        case forwarded
        case scheduled
        case seen
    }
}

public struct SnoozedFlags: DeltaFlags {
    public let shortUid: String
    public let snoozeEndDate: Date

    private enum CodingKeys: String, CodingKey {
        case shortUid = "uid"
        case snoozeEndDate
    }
}
