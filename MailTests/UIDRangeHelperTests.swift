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
@testable import MailCore
import Testing

@Suite
struct UIDRangeHelperTests {
    let helper = UIDRangeHelper()

    @Test("Empty array returns nil")
    func emptyArrayReturnsNil() async throws {
        let result = helper.getCompleteRange(sortedUids: [])
        #expect(result == nil)
    }

    @Test("Single UID returns that UID as a string")
    func singleUID() async throws {
        let result = helper.getCompleteRange(sortedUids: [42])
        let value = try #require(result)
        #expect(value == "42")
    }

    @Test("Two consecutive UIDs collapse to a range")
    func twoConsecutiveUids() async throws {
        let result = helper.getCompleteRange(sortedUids: [3, 4])
        let value = try #require(result)
        #expect(value == "3:4")
    }

    @Test("Non-consecutive UIDs are comma-separated")
    func nonConsecutiveUids() async throws {
        let result = helper.getCompleteRange(sortedUids: [1, 3, 5])
        let value = try #require(result)
        #expect(value == "1,3,5")
    }

    @Test("Mixed contiguous and single UIDs are formatted correctly")
    func mixedRanges() async throws {
        let result = helper.getCompleteRange(sortedUids: [1, 2, 3, 5, 7, 8, 9, 10, 11, 13])
        let value = try #require(result)
        #expect(value == "1:3,5,7:11,13")
    }

    @Test("Large values and trailing single UID")
    func largeValues() async throws {
        let result = helper.getCompleteRange(sortedUids: [1_000_000, 1_000_001, 1_000_003])
        let value = try #require(result)
        #expect(value == "1000000:1000001,1000003")
    }
}
