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

public struct MessagesDelta: Decodable {
    public let deletedShortUids: [String]
    public let addedShortUids: [String]
    public let updated: [MessageFlags]
    public let cursor: String
    public let unreadCount: Int

    private enum CodingKeys: String, CodingKey {
        case deletedShortUids = "deleted"
        case addedShortUids = "added"
        case updated
        case cursor = "signature"
        case unreadCount
    }

    // FIXME: Remove this constructor when mixed Int/String array is fixed by backend
    public init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)

        if let deletedShortUids = try? container.decode([String].self, forKey: .deletedShortUids) {
            self.deletedShortUids = deletedShortUids
        } else {
            deletedShortUids = try container.decode([Int].self, forKey: .deletedShortUids).map { "\($0)" }
            SentrySDK.capture(message: "Received deleted Delta as [Int]")
        }
        if let addedShortUids = try? container.decode([String].self, forKey: .addedShortUids) {
            self.addedShortUids = addedShortUids
        } else {
            addedShortUids = try container.decode([Int].self, forKey: .addedShortUids).map { "\($0)" }
            SentrySDK.capture(message: "Received added Delta as [Int]")
        }
        updated = try container.decode([MessageFlags].self, forKey: .updated)
        cursor = try container.decode(String.self, forKey: .cursor)
        unreadCount = try container.decode(Int.self, forKey: .unreadCount)
    }
}

public class MessageFlags: Decodable {
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
