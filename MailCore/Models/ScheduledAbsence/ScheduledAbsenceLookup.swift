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

public enum ScheduledAbsenceLookup {
    public static let maxEmails = 20
    static let lookAheadDays = 3

    static func window(startingAt date: Date, calendar: Calendar = .current) -> (from: Date, to: Date) {
        let lookAheadDate = calendar.date(byAdding: .day, value: lookAheadDays, to: date) ?? date
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: lookAheadDate)) ?? lookAheadDate
        return (date, startOfNextDay.addingTimeInterval(-1))
    }

    public static func recipients(_ candidates: some Sequence<ScheduledAbsenceRecipient>) -> [ScheduledAbsenceRecipient] {
        var indexByEmail = [String: Int]()
        var result = [ScheduledAbsenceRecipient]()

        for candidate in candidates where !candidate.email.isEmpty {
            if let index = indexByEmail[candidate.email] {
                if result[index].name.isEmpty {
                    result[index] = candidate
                }
            } else if result.count < maxEmails {
                indexByEmail[candidate.email] = result.count
                result.append(candidate)
            }
        }

        return result
    }
}

public extension MailApiScheduledAbsenceFetchable {
    func activeScheduledAbsences(emails: [String], startingAt date: Date) async throws -> [String: [ScheduledAbsenceEntry]] {
        let window = ScheduledAbsenceLookup.window(startingAt: date)
        let absences = try await activeScheduledAbsences(emails: emails, from: window.from, to: window.to)
        return absences.filter { !$0.value.isEmpty }
    }
}
