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

extension ScheduledAbsenceOccurrence {
    public var formattedRange: String {
        return MailResourcesStrings.Localizable.scheduledAbsenceDateRange(formattedStart, formattedEnd)
    }

    var formattedStart: String {
        return format(start)
    }

    /// The end is exclusive, so an end at midnight is displayed as the previous day.
    var formattedEnd: String {
        return format(lastDisplayedDate)
    }

    /// The first day back.
    var formattedReturnDate: String {
        return format(end, style: .scheduledAbsenceDay.weekday(.wide))
    }

    var lastDisplayedDate: Date {
        var calendar = Calendar.current
        calendar.timeZone = displayTimeZone
        guard end > start, calendar.startOfDay(for: end) == end else { return end }
        return end.addingTimeInterval(-1)
    }

    /// Full-day dates are UTC calendar dates.
    private var displayTimeZone: TimeZone {
        return fullday ? TimeZone(identifier: "UTC") ?? .current : .current
    }

    public func chipDescription(now: Date) -> String {
        if state(at: now) == .ongoing {
            return MailResourcesStrings.Localizable.scheduledAbsenceChipOngoing(formattedReturnDate)
        }
        return MailResourcesStrings.Localizable.scheduledAbsenceChipUpcoming(formattedStart, formattedEnd)
    }

    private func format(_ date: Date, style: Date.FormatStyle = .scheduledAbsenceDay) -> String {
        var style = style
        style.timeZone = displayTimeZone
        return date.formatted(.yearIfNeeded(style))
    }
}
