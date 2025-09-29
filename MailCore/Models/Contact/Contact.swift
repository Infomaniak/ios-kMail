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

/// Infomaniak API Contact Object
public struct InfomaniakContact: Codable {
    public var id: String
    public var emails: [String]
    public var name: String?
    public var other: Bool
    public var addressbookIds: Set<Int>?
    public var avatar: String?
    public var groupIds: Set<Int>?
    public var contactedTimes: [String: Int]?

    enum CodingKeys: String, CodingKey {
        case id
        case emails
        case name
        case other
        case addressbookIds = "addressbookId"
        case avatar
        case groupIds = "categories"
        case contactedTimes
    }

    public init(from decoder: Decoder) throws {
        // Custom decoder because of `id` type inconsistency (#I8)
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let id = try? values.decode(Int.self, forKey: .id) {
            self.id = "\(id)"
        } else {
            id = try values.decode(String.self, forKey: .id)
        }
        emails = try values.decode([String].self, forKey: .emails)
        name = try values.decode(String.self, forKey: .name)
        other = try values.decode(Bool.self, forKey: .other)
        if let addressbookIds = try values.decodeIfPresent(Int.self, forKey: .addressbookIds) {
            self.addressbookIds = [addressbookIds]
        }
        avatar = try values.decodeIfPresent(String.self, forKey: .avatar)
        if let groupIds = try values.decodeIfPresent(List<Int>.self, forKey: .groupIds) {
            self.groupIds = Set(groupIds)
        }

        contactedTimes = try values.decodeIfPresent([String: Int].self, forKey: .contactedTimes)
    }
}
