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

/// Computes what the scheduled absence banner should display for a set of recipients.
///
/// Only ongoing (`start <= now < end`) and upcoming (`start > now`) absences are kept, one per recipient (ongoing first).
/// If any absence is ongoing, only ongoing ones are displayed, otherwise upcoming ones.
public struct ScheduledAbsenceSummary: Sendable, Hashable {
    public struct Item: Sendable, Hashable, Identifiable {
        public let email: String
        public let entry: ScheduledAbsenceEntry

        public var id: String {
            return "\(email)-\(entry.id)"
        }

        public init(email: String, entry: ScheduledAbsenceEntry) {
            self.email = email
            self.entry = entry
        }
    }

    public let state: ScheduledAbsenceOccurrence.State
    public let items: [Item]

    public var singleItem: Item? {
        return items.count == 1 ? items.first : nil
    }

    /// `nil` when no recipient has an ongoing or upcoming absence.
    public init?(absencesByEmail: [String: [ScheduledAbsenceEntry]], orderedEmails: [String], now: Date) {
        let relevantEntries = Self.relevantEntryByEmail(absencesByEmail: absencesByEmail, now: now)

        var seenEmails = Set<String>()
        let allItems = orderedEmails.map { $0.lowercased() }
            .filter { seenEmails.insert($0).inserted }
            .compactMap { email in relevantEntries[email].map { Item(email: email, entry: $0) } }
        let ongoingItems = allItems.filter { $0.entry.occurrence.state(at: now) == .ongoing }

        if !ongoingItems.isEmpty {
            state = .ongoing
            items = ongoingItems
        } else if !allItems.isEmpty {
            state = .upcoming
            items = allItems
        } else {
            return nil
        }
    }

    public func bannerText(displayName: (String) -> String) -> String {
        guard let item = singleItem else {
            return state == .ongoing
                ? MailResourcesStrings.Localizable.scheduledAbsenceBannerOngoingMultiple(items.count)
                : MailResourcesStrings.Localizable.scheduledAbsenceBannerUpcomingMultiple(items.count)
        }

        let occurrence = item.entry.occurrence
        return state == .ongoing
            ? MailResourcesStrings.Localizable.scheduledAbsenceBannerOngoingSingle(
                displayName(item.email),
                occurrence.formattedReturnDate
            )
            : MailResourcesStrings.Localizable.scheduledAbsenceBannerUpcomingSingle(
                displayName(item.email),
                occurrence.formattedStart,
                occurrence.formattedEnd
            )
    }

    /// "Absence message" (single, only with an auto-reply) or "See dates" (multiple).
    public var actionTitle: String? {
        guard let item = singleItem else { return MailResourcesStrings.Localizable.scheduledAbsenceSeeDatesButton }
        guard item.entry.absence.displayableAutoReplyContent != nil else { return nil }
        return MailResourcesStrings.Localizable.scheduledAbsenceMessageButton
    }

    /// Title of the "See dates" sheet.
    public var recipientsTitle: String {
        return state == .ongoing
            ? MailResourcesStrings.Localizable.scheduledAbsenceRecipientsTitle(items.count)
            : MailResourcesStrings.Localizable.scheduledAbsenceUpcomingRecipientsTitle(items.count)
    }

    /// Absence description of each recipient (e.g. displayed in the recipient menu), keyed by lowercased email.
    public static func descriptionsByEmail(
        absencesByEmail: [String: [ScheduledAbsenceEntry]],
        now: Date
    ) -> [String: String] {
        return relevantEntryByEmail(absencesByEmail: absencesByEmail, now: now)
            .mapValues { $0.occurrence.chipDescription(now: now) }
    }

    /// One absence per recipient, keyed by lowercased email: the first ongoing one, else the first upcoming one.
    /// Following absences that overlap or touch it are merged into it, so the displayed end is the actual return.
    static func relevantEntryByEmail(
        absencesByEmail: [String: [ScheduledAbsenceEntry]],
        now: Date
    ) -> [String: ScheduledAbsenceEntry] {
        let lowercasedAbsences = absencesByEmail.reduce(into: [String: [ScheduledAbsenceEntry]]()) { result, element in
            result[element.key.lowercased(), default: []].append(contentsOf: element.value)
        }

        return lowercasedAbsences.compactMapValues { entries in
            let sortedEntries = entries.sorted { $0.occurrence.start < $1.occurrence.start }
            guard let entry = sortedEntries.first(where: { $0.occurrence.state(at: now) == .ongoing })
                ?? sortedEntries.first(where: { $0.occurrence.state(at: now) == .upcoming }) else { return nil }
            return mergingChainedEntries(into: entry, sortedEntries: sortedEntries)
        }
    }

    /// Extends `entry` with the following entries of the same kind (full-day or not) starting before or at its end.
    private static func mergingChainedEntries(
        into entry: ScheduledAbsenceEntry,
        sortedEntries: [ScheduledAbsenceEntry]
    ) -> ScheduledAbsenceEntry {
        let occurrence = entry.occurrence
        var end = occurrence.end
        for other in sortedEntries where other.occurrence.fullday == occurrence.fullday && other.occurrence.start <= end {
            end = max(end, other.occurrence.end)
        }

        guard end != occurrence.end else { return entry }
        return ScheduledAbsenceEntry(
            absence: entry.absence,
            occurrence: ScheduledAbsenceOccurrence(start: occurrence.start, end: end, fullday: occurrence.fullday)
        )
    }
}
