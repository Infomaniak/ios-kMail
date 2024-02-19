/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

final class ProxySubBody: Codable {
    public var body: ProxyBody

    public var name: String?
    public var type: String?
    public var date: Date?
    public var subject: String?
    public var from = [Recipient]()
    public var to = [Recipient]()
    public var partId: String?

    public func realmObject() -> SubBody {
        // truncate message if needed
        let truncatedValue = body.value?.truncatedForRealmIfNeeded

        let subBody = SubBody()
        subBody.value = truncatedValue
        subBody.type = body.type
        subBody.name = name
        subBody.subBodyType = type
        subBody.date = date
        subBody.subject = subject
        subBody.from = from.toRealmList()
        subBody.to = to.toRealmList()
        subBody.partId = partId
        return subBody
    }
}

public final class SubBody: BodyContent {
    @Persisted public var name: String?
    @Persisted public var subBodyType: String?
    @Persisted public var date: Date?
    @Persisted public var subject: String?
    @Persisted public var from = List<Recipient>()
    @Persisted public var to = List<Recipient>()
    @Persisted public var partId: String?
}

extension ProxyBody {
    private var allSubBodyRecursively: [ProxySubBody] {
        let items = subBody ?? []
        return items + items.flatMap { $0.body.allSubBodyRecursively }
    }

    func flattenSubBody() -> List<SubBody> {
        return allSubBodyRecursively.map { $0.realmObject() }.toRealmList()
    }
}

public class BodyContent: EmbeddedObject {
    /// Public facing "value", wrapping `valueData`
    public var value: String? {
        get {
            guard let decompressedString = valueData?.decompressedString() else {
                return nil
            }

            return decompressedString
        } set {
            guard let data = newValue?.compressed() else {
                valueData = nil
                return
            }

            valueData = data
        }
    }

    @Persisted public var type: String?
    @Persisted var valueData: Data?
}
