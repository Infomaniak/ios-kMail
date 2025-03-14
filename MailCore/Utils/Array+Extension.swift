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

public extension Array where Element: RealmCollectionValue {
    func toRealmList() -> List<Element> {
        let list = List<Element>()
        list.append(objectsIn: self)
        return list
    }

    func toRealmSet() -> MutableSet<Element> {
        let set = MutableSet<Element>()
        set.insert(objectsIn: self)
        return set
    }
}

public extension Array where Element: Hashable {
    func toSet() -> Set<Element> {
        return Set(self)
    }
}

public extension List {
    func toArray() -> [Element] {
        return Array(self)
    }
}

public extension LazyFilterSequence {
    func toArray() -> [Base.Element] {
        return Array(self)
    }
}

public extension LazyMapSequence {
    func toArray() -> [Element] {
        return Array(self)
    }
}

public extension Set {
    func toArray() -> [Element] {
        return Array(self)
    }
}

public extension MutableSet {
    func upsert<S: Sequence>(objectsIn objects: S) where S.Iterator.Element == Element {
        removeAll()
        insert(objectsIn: objects)
    }
}
