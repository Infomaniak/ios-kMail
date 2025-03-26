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
public struct InfomaniakContact: Codable, Identifiable {
    public var id: String
    public var color: String
    public var emails: [String]
    public var firstname: String?
    public var lastname: String?
    public var name: String?
    public var other: Bool
    public var uuid: String?
    public var addressbookId: Int?
    public var avatar: String?
    public var favorite: Bool?
    public var nickname: String?
    public var organization: String?
    public var groupContactId: List<Int>?
    public var contactedTimes: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case color
        case emails
        case firstname
        case lastname
        case name
        case other
        case uuid
        case addressbookId
        case avatar
        case favorite
        case nickname
        case organization
        case groupContactId = "categories"
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
        color = try values.decode(String.self, forKey: .color)
        emails = try values.decode([String].self, forKey: .emails)
        firstname = try values.decodeIfPresent(String.self, forKey: .firstname)
        lastname = try values.decodeIfPresent(String.self, forKey: .lastname)
        name = try values.decode(String.self, forKey: .name)
        other = try values.decode(Bool.self, forKey: .other)
        uuid = try values.decodeIfPresent(String.self, forKey: .uuid)
        addressbookId = try values.decodeIfPresent(Int.self, forKey: .addressbookId)
        avatar = try values.decodeIfPresent(String.self, forKey: .avatar)
        favorite = try values.decodeIfPresent(Bool.self, forKey: .favorite)
        nickname = try values.decodeIfPresent(String.self, forKey: .nickname)
        organization = try values.decodeIfPresent(String.self, forKey: .organization)
        groupContactId = try values.decodeIfPresent(List<Int>.self, forKey: .groupContactId)
        if let rawContactedTimes = try values.decodeIfPresent([String: Int].self, forKey: .contactedTimes) {
            contactedTimes = rawContactedTimes.reduce(into: 0) { result, element in
                result += element.value
            }
        }
    }
}
