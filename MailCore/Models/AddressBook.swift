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
import MailResources

public struct AddressBookResult: Codable {
    var addressbooks: [AddressBook]
}

public final class AddressBook: Object, Codable, Identifiable {
    @Persisted public var id: Int
    @Persisted(primaryKey: true) public var uuid: String
    @Persisted public var name: String
    @Persisted public var isDefault: Bool
    @Persisted public var groupContact: List<GroupContact>

    private var organization = ""
    private var isDynamicOrganisation = false

    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case name
        case isDefault = "default"
        case groupContact = "categories"
        case organization = "accountName"
        case isDynamicOrganisation = "isDynamicOrganisationMemberDirectory"
    }

    override public init() {
        super.init()
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedId = try container.decode(Int.self, forKey: .id)
        let decodedUuid = try container.decode(String.self, forKey: .uuid)
        let decodedName = try container.decode(String.self, forKey: .name)
        let decodedIsDefault = try container.decode(Bool.self, forKey: .isDefault)
        let decodedGroupContacts = try container.decode(List<GroupContact>.self, forKey: .groupContact)
        let decodedOrganization = try container.decodeIfPresent(String.self, forKey: .organization) ?? MailResourcesStrings.Localizable.otherOrganisation
        let decodedIsDynamicOrganisation = try container.decode(Bool.self, forKey: .isDynamicOrganisation)

        super.init()

        id = decodedId
        name = decodedIsDynamicOrganisation ? decodedOrganization : decodedName
        uuid = decodedUuid
        isDefault = decodedIsDefault
        groupContact = decodedGroupContacts
    }
}

extension AddressBook: ContactAutocompletable {
    public var contactId: String {
        return String(id)
    }

    public var autocompletableName: String {
        return name
    }
}
