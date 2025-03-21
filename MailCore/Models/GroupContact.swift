/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import RealmSwift

// AddressBook Categories
public final class GroupContact: Object, Codable {
    @Persisted public var id: Int

    @Persisted public var name: String

    public func isSameContactAutocompletable(as contactAutoCompletable: any ContactAutocompletable) -> Bool {
        return name == contactAutoCompletable.autocompletableName
    }
}

extension GroupContact: ContactAutocompletable {
    public var contactId: String {
        return String(id)
    }

    public var autocompletableName: String {
        return name
    }
}
