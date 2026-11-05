/*
 Infomaniak Mail - iOS App
 Copyright (C) 2026 Infomaniak Network SA

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

@Suite("YearIfNeededFormatStyle")
struct YearIfNeededFormatStyleTests {
    private let base = Date.FormatStyle(locale: Locale(identifier: "en_US"), timeZone: TimeZone(identifier: "UTC")!)
        .day()
        .month(.wide)
    private let now = ISO8601DateFormatter().date(from: "2026-11-05T12:00:00Z")!

    @Test func omitsYearInSameYear() {
        let date = ISO8601DateFormatter().date(from: "2026-05-09T00:00:00Z")!
        #expect(date.formatted(.yearIfNeeded(base, now: now)) == "May 9")
    }

    @Test func addsYearInAnotherYear() {
        let date = ISO8601DateFormatter().date(from: "2027-01-02T00:00:00Z")!
        #expect(date.formatted(.yearIfNeeded(base, now: now)) == "January 2, 2027")
    }

    @Test func comparesYearsInStyleTimeZone() {
        let date = ISO8601DateFormatter().date(from: "2025-12-31T23:30:00Z")!
        #expect(date.formatted(.yearIfNeeded(base, now: now)) == "December 31, 2025")
    }
}
