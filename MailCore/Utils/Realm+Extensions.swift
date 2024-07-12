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
import InfomaniakCoreDB
import RealmSwift

public extension Object {
    func fresh(using realm: Realm) -> Self? {
        guard let primaryKey = objectSchema.primaryKeyProperty?.name,
              let primaryKeyValue = value(forKey: primaryKey) else {
            return nil
        }

        return realm.object(ofType: Self.self, forPrimaryKey: primaryKeyValue)
    }

    func fresh(transactionable: Transactionable) -> Self? {
        guard let primaryKey = objectSchema.primaryKeyProperty?.name,
              let primaryKeyValue = value(forKey: primaryKey) else {
            return nil
        }

        return transactionable.fetchObject(ofType: Self.self, forPrimaryKey: primaryKeyValue)
    }

    /// Get an updated frozen copy for a given object
    func refresh() -> Self {
        guard realm != nil else { return self }

        guard let liveMessage = thaw(),
              let realm = liveMessage.realm else {
            return self
        }

        realm.refresh()
        return liveMessage.freeze()
    }
}
