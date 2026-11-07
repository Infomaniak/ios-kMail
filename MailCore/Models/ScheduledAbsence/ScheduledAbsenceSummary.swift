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
/// Only ongoing (`start <= now < end`) and upcoming (`start > now`) absences are kept.
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

    public enum Mode: Sendable, Hashable {
        case ongoingSingle(Item)
        case upcomingSingle(Item)
        case ongoingMultiple([Item])
        case upcomingMultiple([Item])
    }

    public let mode: Mode?
    /// Hides the "Absence message" action when the auto-reply is already displayed (e.g. the read message is the auto-reply).
    public var isAutoReplyAlreadyDisplayed = false

    public init(absencesByEmail: [String: [ScheduledAbsenceEntry]], orderedEmails: [String], now: Date) {
        let lowercasedAbsences = absencesByEmail.reduce(into: [String: [ScheduledAbsenceEntry]]()) { result, element in
            result[element.key.lowercased(), default: []].append(contentsOf: element.value)
        }

        var seenEmails = Set<String>()
        var ongoingItems = [Item]()
        var upcomingItems = [Item]()
        for email in orderedEmails {
            let lowercasedEmail = email.lowercased()
            guard seenEmails.insert(lowercasedEmail).inserted,
                  let entries = lowercasedAbsences[lowercasedEmail] else { continue }

            for entry in entries.sorted(by: { $0.occurrence.start < $1.occurrence.start }) {
                if entry.occurrence.isOngoing(at: now) {
                    ongoingItems.append(Item(email: lowercasedEmail, entry: entry))
                } else if entry.occurrence.isUpcoming(at: now) {
                    upcomingItems.append(Item(email: lowercasedEmail, entry: entry))
                }
            }
        }

        if !ongoingItems.isEmpty {
            mode = ongoingItems.count == 1 ? .ongoingSingle(ongoingItems[0]) : .ongoingMultiple(ongoingItems)
        } else if !upcomingItems.isEmpty {
            mode = upcomingItems.count == 1 ? .upcomingSingle(upcomingItems[0]) : .upcomingMultiple(upcomingItems)
        } else {
            mode = nil
        }
    }

    public var displayedEntries: [Item] {
        switch mode {
        case .ongoingSingle(let item), .upcomingSingle(let item):
            return [item]
        case .ongoingMultiple(let items), .upcomingMultiple(let items):
            return items
        case nil:
            return []
        }
    }

    public var isUpcoming: Bool {
        switch mode {
        case .upcomingSingle, .upcomingMultiple:
            return true
        case .ongoingSingle, .ongoingMultiple, nil:
            return false
        }
    }

    public var isSingle: Bool {
        switch mode {
        case .ongoingSingle, .upcomingSingle:
            return true
        case .ongoingMultiple, .upcomingMultiple, nil:
            return false
        }
    }

    /// The single displayed item, if any.
    public var singleItem: Item? {
        guard isSingle else { return nil }
        return displayedEntries.first
    }

    /// Banner text. `displayName` is only used in single modes (falls back to the email).
    public func bannerText(displayName: String?, locale: Locale = .current) -> String? {
        switch mode {
        case .ongoingSingle(let item):
            return MailResourcesStrings.Localizable.scheduledAbsenceBannerOngoingSingle(
                name(displayName, fallback: item.email),
                item.entry.occurrence.formattedReturnDate(locale: locale)
            )
        case .upcomingSingle(let item):
            return MailResourcesStrings.Localizable.scheduledAbsenceBannerUpcomingSingle(
                name(displayName, fallback: item.email),
                item.entry.occurrence.formattedStartDay(locale: locale),
                item.entry.occurrence.formattedLastDisplayedDay(locale: locale)
            )
        case .ongoingMultiple(let items):
            return MailResourcesStrings.Localizable.scheduledAbsenceBannerOngoingMultiple(items.count)
        case .upcomingMultiple(let items):
            return MailResourcesStrings.Localizable.scheduledAbsenceBannerUpcomingMultiple(items.count)
        case nil:
            return nil
        }
    }

    /// Banner action title: "Absence message" (single, only with an auto-reply) or "See dates" (multiple).
    public var actionTitle: String? {
        switch mode {
        case .ongoingSingle(let item), .upcomingSingle(let item):
            guard item.entry.absence.displayableAutoReplyContent != nil, !isAutoReplyAlreadyDisplayed else { return nil }
            return MailResourcesStrings.Localizable.scheduledAbsenceMessageButton
        case .ongoingMultiple, .upcomingMultiple:
            return MailResourcesStrings.Localizable.scheduledAbsenceSeeDatesButton
        case nil:
            return nil
        }
    }

    /// Title of the "See dates" sheet.
    public var recipientsTitle: String? {
        switch mode {
        case .ongoingMultiple(let items):
            return MailResourcesStrings.Localizable.scheduledAbsenceRecipientsTitle(items.count)
        case .upcomingMultiple(let items):
            return MailResourcesStrings.Localizable.scheduledAbsenceUpcomingRecipientsTitle(items.count)
        case .ongoingSingle, .upcomingSingle, nil:
            return nil
        }
    }

    private func name(_ displayName: String?, fallback: String) -> String {
        guard let displayName, !displayName.isEmpty else { return fallback }
        return displayName
    }
}
