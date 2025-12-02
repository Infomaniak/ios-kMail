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
        let sortedUniqueUids = messages.lazy.compactMap(\.shortUid).sorted()
        return getCompleteRange(sortedUniqueUids: sortedUniqueUids)
    }
}

struct UIDRangeHelper {
    func getCompleteRange(uids: [Int]) -> String? {
        let sortedUniqueUids = Set(uids).sorted()
        return getCompleteRange(sortedUniqueUids: sortedUniqueUids)
    }

    private func getCompleteRange(sortedUniqueUids: [Int]) -> String? {
        guard let firstUid = sortedUniqueUids.first else { return nil }

        var components: [String] = []

        var rangeStart = firstUid
        var previousUid = firstUid

        for uid in sortedUniqueUids.dropFirst() {
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
