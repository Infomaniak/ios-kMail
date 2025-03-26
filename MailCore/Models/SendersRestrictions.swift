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

public class SendersRestrictions: EmbeddedObject, Codable {
    @Persisted public var authorizedSenders: List<Sender>
    @Persisted public var blockedSenders: List<Sender>

    enum CodingKeys: String, CodingKey {
        case authorizedSenders
        case blockedSenders
    }

    public func encode(to encoder: Encoder) throws {
        let authorized: [String] = authorizedSenders.map { $0.email }
        let blocked: [String] = blockedSenders.map { $0.email }

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(authorized, forKey: .authorizedSenders)
        try container.encode(blocked, forKey: .blockedSenders)
    }
}

public class Sender: EmbeddedObject, Codable {
    @Persisted public var email: String
}
