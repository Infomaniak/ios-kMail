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

public class DraftReminder: EmbeddedObject, Codable {
    @Persisted public var delta: Int
    @Persisted public var display: Bool

    enum CodingKeys: String, CodingKey {
        case delta
        case display
    }

    public init(delta: Int, display: Bool) {
        self.delta = delta
        self.display = display
    }

    override public init() {
        delta = 60
        display = true
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encodeIfPresent(delta, forKey: .delta)
        try? container.encodeIfPresent(display, forKey: .display)
    }
}
