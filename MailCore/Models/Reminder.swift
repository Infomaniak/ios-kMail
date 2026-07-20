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
import RealmSwift

public class Reminder: EmbeddedObject, Codable {
    /// UUID of the reminder. Only present when the current user is the creator of the reminder.
    @Persisted public var uuid: String?
    @Persisted public var date: Date?

    // If a message is scheduled we will have access to this data to show reminder header
    @Persisted public var delta: Int?
    @Persisted public var visibility: Bool?

    enum CodingKeys: String, CodingKey {
        case uuid
        case date
        case delta
        case display
    }

    override public init() {
        super.init()
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let delta = try? container.decodeIfPresent(Int.self, forKey: .delta) {
            self.delta = delta
            visibility = try? container.decodeIfPresent(Bool.self, forKey: .display)
        } else {
            uuid = try? container.decodeIfPresent(String.self, forKey: .uuid)
            date = try? container.decodeIfPresent(Date.self, forKey: .date)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encodeIfPresent(uuid, forKey: .uuid)
        try? container.encodeIfPresent(date, forKey: .date)
        try? container.encodeIfPresent(delta, forKey: .delta)
        try? container.encodeIfPresent(visibility, forKey: .display)
    }

    public var canEdit: Bool {
        return uuid != nil
    }
}
