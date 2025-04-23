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

public struct MessagesDelta<Flags: DeltaFlags>: Decodable, Sendable {
    public let deletedShortUids: [String]
    public let addedShortUids: [String]
    public let updated: [Flags]
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

public extension MessagesDelta {
    func ensureValidDelta() throws {
        let deletedCount = deletedShortUids.count
        let addedCount = addedShortUids.count
        let updatedCount = updated.count

        guard deletedCount < Constants.maxChangesCount,
              addedCount < Constants.maxChangesCount,
              updatedCount < Constants.maxChangesCount else {
            SentrySDK.capture(message: "tooManyDiffs") { scope in
                scope.setExtras([
                    "cursor": cursor,
                    "deletedCount": deletedCount,
                    "addedCount": addedCount,
                    "updatedCount": updatedCount
                ])
            }

            throw MailboxManager.ErrorDomain.tooManyDiffs
        }
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
