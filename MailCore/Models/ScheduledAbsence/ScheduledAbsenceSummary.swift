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
import MailResources

public struct ScheduledAbsenceSummary: Sendable, Hashable {
    public struct AbsentRecipient: Sendable, Hashable, Identifiable {
        public let email: String
        public let name: String
        public let entry: ScheduledAbsenceEntry
        public let absenceDescription: String

        public var id: String {
            return "\(email)-\(entry.id)"
        }

        public var displayName: String {
            return name.isEmpty ? email : name
        }

        init(recipient: ScheduledAbsenceRecipient, entry: ScheduledAbsenceEntry, now: Date) {
            email = recipient.email
            name = recipient.name.caseInsensitiveCompare(recipient.email) == .orderedSame ? "" : recipient.name
            self.entry = entry
            absenceDescription = entry.occurrence.chipDescription(now: now)
        }
    }

    public let state: ScheduledAbsenceOccurrence.State
    public let absentRecipients: [AbsentRecipient]
    public let descriptionsByEmail: [String: String]
    public let now: Date

    public var singleAbsentRecipient: AbsentRecipient? {
        return absentRecipients.count == 1 ? absentRecipients.first : nil
    }

    public init?(
        absencesByEmail: [String: [ScheduledAbsenceEntry]],
        orderedRecipients: [ScheduledAbsenceRecipient],
        now: Date
    ) {
        self.now = now
        let relevantEntries = Self.relevantEntryByEmail(absencesByEmail: absencesByEmail, now: now)

        let allAbsentRecipients = orderedRecipients.compactMap { recipient in
            relevantEntries[recipient.email].map { AbsentRecipient(recipient: recipient, entry: $0, now: now) }
        }
        descriptionsByEmail = Dictionary(allAbsentRecipients.map { ($0.email, $0.absenceDescription) }) { first, _ in first }
        let ongoingAbsentRecipients = allAbsentRecipients.filter { $0.entry.occurrence.state(at: now) == .ongoing }

        if !ongoingAbsentRecipients.isEmpty {
            state = .ongoing
            absentRecipients = ongoingAbsentRecipients
        } else if !allAbsentRecipients.isEmpty {
            state = .upcoming
            absentRecipients = allAbsentRecipients
        } else {
            return nil
        }
    }

    public var bannerText: String {
        guard let absentRecipient = singleAbsentRecipient else {
            return state == .ongoing
                ? MailResourcesStrings.Localizable.scheduledAbsenceBannerOngoingMultiple(absentRecipients.count)
                : MailResourcesStrings.Localizable.scheduledAbsenceBannerUpcomingMultiple(absentRecipients.count)
        }

        let occurrence = absentRecipient.entry.occurrence
        return state == .ongoing
            ? MailResourcesStrings.Localizable.scheduledAbsenceBannerOngoingSingle(
                absentRecipient.displayName,
                occurrence.formattedReturnDate(now: now)
            )
            : MailResourcesStrings.Localizable.scheduledAbsenceBannerUpcomingSingle(
                absentRecipient.displayName,
                occurrence.formattedStart(now: now),
                occurrence.formattedEnd(now: now)
            )
    }

    public var actionTitle: String? {
        guard let absentRecipient = singleAbsentRecipient else {
            return MailResourcesStrings.Localizable.scheduledAbsenceSeeDatesButton
        }
        guard absentRecipient.entry.absence.displayableAutoReplyContent != nil else { return nil }
        return MailResourcesStrings.Localizable.scheduledAbsenceMessageButton
    }

    public var recipientsTitle: String {
        return state == .ongoing
            ? MailResourcesStrings.Localizable.scheduledAbsenceRecipientsTitle(absentRecipients.count)
            : MailResourcesStrings.Localizable.scheduledAbsenceUpcomingRecipientsTitle(absentRecipients.count)
    }

    static func relevantEntryByEmail(
        absencesByEmail: [String: [ScheduledAbsenceEntry]],
        now: Date,
        timeZone: TimeZone = .current
    ) -> [String: ScheduledAbsenceEntry] {
        return absencesByEmail.compactMapValues { entries in
            let sortedEntries = entries.sorted {
                $0.occurrence.localStart(timeZone: timeZone) < $1.occurrence.localStart(timeZone: timeZone)
            }
            return sortedEntries.first { $0.occurrence.state(at: now, timeZone: timeZone) == .ongoing }
                ?? sortedEntries.first { $0.occurrence.state(at: now, timeZone: timeZone) == .upcoming }
        }
    }
}
