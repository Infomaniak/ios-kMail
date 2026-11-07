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

public struct ScheduledAbsenceEntry: Decodable, Sendable, Hashable, Identifiable {
    public let absence: ScheduledAbsence
    public let occurrence: ScheduledAbsenceOccurrence

    public var id: String {
        return "\(absence.uuid)-\(occurrence.start.timeIntervalSince1970)"
    }

    public init(absence: ScheduledAbsence, occurrence: ScheduledAbsenceOccurrence) {
        self.absence = absence
        self.occurrence = occurrence
    }
}

/// `data` payload of `/pim/scheduled-absence/active`: `{ "<email>": [Entry] | null }`.
/// Emails differing only by case are merged, without duplicating the same entry.
struct ScheduledAbsencesResponse: Decodable {
    let absencesByEmail: [String: [ScheduledAbsenceEntry]]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawData = try container.decode([String: [ScheduledAbsenceEntry]?].self)

        var absencesByEmail = [String: [ScheduledAbsenceEntry]]()
        for (email, entries) in rawData {
            let key = email.lowercased()
            var mergedEntries = absencesByEmail[key] ?? []
            for entry in entries ?? [] where !mergedEntries.contains(where: { $0.id == entry.id }) {
                mergedEntries.append(entry)
            }
            absencesByEmail[key] = mergedEntries
        }
        self.absencesByEmail = absencesByEmail
    }
}
