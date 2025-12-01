/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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

extension UIDRangeHelper {
    func getCompleteRange(messages: MutableSet<Message>) -> String? {
        let sortedUids = messages.lazy.compactMap(\.shortUid).sorted()
        return getCompleteRange(sortedUids: sortedUids)
    }
}

struct UIDRangeHelper {
    func getCompleteRange(sortedUids: [Int]) -> String? {
        guard let firstUid = sortedUids.first else { return nil }

        var components: [String] = []

        var rangeStart = firstUid
        var previousUid = firstUid

        for uid in sortedUids.dropFirst() {
            if uid == previousUid + 1 {
                previousUid = uid
                continue
            }

            if rangeStart == previousUid {
                components.append(String(rangeStart))
            } else {
                components.append("\(rangeStart):\(previousUid)")
            }

            rangeStart = uid
            previousUid = uid
        }

        if rangeStart == previousUid {
            components.append(String(rangeStart))
        } else {
            components.append("\(rangeStart):\(previousUid)")
        }

        return components.joined(separator: ",")
    }
}
