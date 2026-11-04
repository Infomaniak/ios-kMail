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

public extension ScheduledAbsenceOccurrence {
    /// The first day back (full-day occurrences use an exclusive end).
    var returnDate: Date {
        return end
    }

    /// The last date to display in a range: full-day occurrences have an exclusive end.
    var lastDisplayedDate: Date {
        return fullday ? end.addingTimeInterval(-1) : end
    }

    /// Full-day dates are UTC calendar dates.
    var displayTimeZone: TimeZone {
        return fullday ? TimeZone(identifier: "UTC") ?? .current : .current
    }

    /// e.g. "vendredi 8 mai"
    var formattedReturnDate: String {
        return formattedReturnDate(locale: .current)
    }

    /// e.g. "Du 4 mai au 8 mai"
    var formattedRange: String {
        return formattedRange(locale: .current)
    }

    func formattedReturnDate(locale: Locale) -> String {
        return returnDate.formatted(dateStyle(locale: locale).weekday(.wide).day().month(.wide))
    }

    func formattedStartDay(locale: Locale = .current) -> String {
        return start.formatted(dateStyle(locale: locale).day().month(.wide))
    }

    func formattedLastDisplayedDay(locale: Locale = .current) -> String {
        return lastDisplayedDate.formatted(dateStyle(locale: locale).day().month(.wide))
    }

    func formattedRange(locale: Locale) -> String {
        return MailResourcesStrings.Localizable.scheduledAbsenceDateRange(
            formattedStartDay(locale: locale),
            formattedLastDisplayedDay(locale: locale)
        )
    }

    /// Description for a recipient chip, e.g. "Absence en cours, de retour le vendredi 8 mai".
    func chipDescription(now: Date, locale: Locale = .current) -> String {
        if isOngoing(at: now) {
            return MailResourcesStrings.Localizable.scheduledAbsenceChipOngoing(formattedReturnDate(locale: locale))
        }
        return MailResourcesStrings.Localizable.scheduledAbsenceChipUpcoming(
            formattedStartDay(locale: locale),
            formattedLastDisplayedDay(locale: locale)
        )
    }

    private func dateStyle(locale: Locale) -> Date.FormatStyle {
        var calendar = Calendar.current
        calendar.timeZone = displayTimeZone
        return Date.FormatStyle(locale: locale, calendar: calendar, timeZone: displayTimeZone)
    }
}
