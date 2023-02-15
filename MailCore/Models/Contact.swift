/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import RealmSwift

public class Contact: Object, Codable, Identifiable {
    @Persisted(primaryKey: true) public var id: String
    @Persisted public var color: String
//    @Persisted public var contactedTimes: [String: Int]
    @Persisted public var emails: List<String>
    @Persisted public var firstname: String?
    @Persisted public var lastname: String?
    @Persisted public var name: String?
    @Persisted public var other: Bool
    @Persisted public var uuid: String?
    @Persisted public var addressbookId: Int?
    @Persisted public var avatar: String?
//    @Persisted public var categories: [Int]?
    @Persisted public var favorite: Bool?
    @Persisted public var nickname: String?
    @Persisted public var organization: String?

    enum CodingKeys: String, CodingKey {
        case id
        case color
//        case contactedTimes
        case emails
        case firstname
        case lastname
        case name
        case other
        case uuid
        case addressbookId
        case avatar
//        case categories
        case favorite
        case nickname
        case organization
    }

    override init() {
        super.init()
    }

    public required init(from decoder: Decoder) throws {
        super.init()
        // Custom decoder because of `id` type inconsistency (#I8)
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let id = try? values.decode(Int.self, forKey: .id) {
            self.id = "\(id)"
        } else {
            id = try values.decode(String.self, forKey: .id)
        }
        color = try values.decode(String.self, forKey: .color)
        // Will need to investigate this later
//        contactedTimes = (try? values.decode([String: Int].self, forKey: .contactedTimes)) ?? [:]
        emails = try values.decode(List<String>.self, forKey: .emails)
        firstname = try values.decodeIfPresent(String.self, forKey: .firstname)
        lastname = try values.decodeIfPresent(String.self, forKey: .lastname)
        name = try values.decode(String.self, forKey: .name)
        other = try values.decode(Bool.self, forKey: .other)
        uuid = try values.decodeIfPresent(String.self, forKey: .uuid)
        addressbookId = try values.decodeIfPresent(Int.self, forKey: .addressbookId)
        avatar = try values.decodeIfPresent(String.self, forKey: .avatar)
//        categories = try values.decodeIfPresent([Int].self, forKey: .categories)
        favorite = try values.decodeIfPresent(Bool.self, forKey: .favorite)
        nickname = try values.decodeIfPresent(String.self, forKey: .nickname)
        organization = try values.decodeIfPresent(String.self, forKey: .organization)
    }
}
