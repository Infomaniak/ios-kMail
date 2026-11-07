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

public struct ScheduledAbsenceOccurrence: Decodable, Sendable, Hashable {
    public let start: Date
    /// Exclusive end. For full-day occurrences, it is the first day back (UTC calendar date).
    public let end: Date
    public let fullday: Bool

    enum CodingKeys: String, CodingKey {
        case start
        case end
        case fullday
    }

    public init(start: Date, end: Date, fullday: Bool) {
        self.start = start
        self.end = end
        self.fullday = fullday
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        start = try container.decode(Date.self, forKey: .start)
        end = try container.decode(Date.self, forKey: .end)
        fullday = (try? container.decodeIfPresent(Bool.self, forKey: .fullday)) ?? false
    }

    public enum State {
        case upcoming
        case ongoing
        case past
    }

    public func state(at now: Date, timeZone: TimeZone = .current) -> State {
        let referenceDate = referenceDate(for: now, timeZone: timeZone)
        if referenceDate < start {
            return .upcoming
        }
        if referenceDate < end {
            return .ongoing
        }
        return .past
    }

    /// Full-day occurrences are UTC calendar dates compared by day: map `now` to its local calendar date anchored in UTC.
    private func referenceDate(for now: Date, timeZone: TimeZone) -> Date {
        guard fullday, let utcTimeZone = TimeZone(identifier: "UTC") else { return now }

        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = timeZone
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = utcTimeZone

        let components = localCalendar.dateComponents([.year, .month, .day], from: now)
        return utcCalendar.date(from: components) ?? now
    }
}
