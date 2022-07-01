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

public struct AddressBookResult: Codable {
    var addressbooks: [AddressBook]
    var addressbook: AddressBook?

    enum CodingKeys: String, CodingKey {
        case addressbooks
        case addressbook = "default"
    }
}

public class AddressBook: Object, Codable, Identifiable {
    @Persisted public var id: Int
    @Persisted(primaryKey: true) public var uuid: String
    // public var categories: [Category]
    @Persisted public var color: String
    @Persisted public var name: String
    @Persisted public var descriptionValue: String
    @Persisted public var isActivated: Bool
    @Persisted public var isHidden: Bool
    @Persisted public var isPending: Bool
    @Persisted public var isShared: Bool
    // public var owner: Owner
    @Persisted public var principalUri: String
    @Persisted public var rights: String
    @Persisted public var userId: Int

    public var isMain: Bool {
        return principalUri.starts(with: "principals")
    }

    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case color
        case name
        case descriptionValue = "description"
        case isActivated
        case isHidden
        case isPending
        case isShared
        case principalUri
        case rights
        case userId
    }
}
