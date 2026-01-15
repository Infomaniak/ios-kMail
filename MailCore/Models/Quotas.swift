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
import RealmSwift

public class Quotas: EmbeddedObject, Codable {
    @Persisted public var size: Int
    @Persisted public var sizeCheckedAt: Int64
    @Persisted public var maxStorage: Int64?

    public var progression: Double {
        guard let maxStorage else {
            return Constants.minimumQuotasProgressionToDisplay
        }
        let currentProgression = Double(size) / Double(maxStorage)
        return max(Constants.minimumQuotasProgressionToDisplay, currentProgression)
    }

    override public init() {
        super.init()
    }

    enum CodingKeys: String, CodingKey {
        case size
        case sizeCheckedAt
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // For some reason sometimes backend returns null instead of real value
        size = try container.decodeIfPresent(Int.self, forKey: .size) ?? 0
        sizeCheckedAt = try container.decode(Int64.self, forKey: .sizeCheckedAt)
    }
}
