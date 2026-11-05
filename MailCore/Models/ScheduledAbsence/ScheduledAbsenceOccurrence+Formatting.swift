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
    public func formattedRange(now: Date) -> String {
        return MailResourcesStrings.Localizable.scheduledAbsenceDateRange(formattedStart(now: now), formattedEnd(now: now))
    }

    func formattedStart(now: Date) -> String {
        return format(start, now: now)
    }

    func formattedEnd(now: Date) -> String {
        return format(lastDisplayedDate, now: now)
    }

    func formattedReturnDate(now: Date) -> String {
        return format(end, style: .scheduledAbsenceDay.weekday(.wide), now: now)
    }

    var lastDisplayedDate: Date {
        guard !displaysTime, end > start else { return end }
        return end.addingTimeInterval(-1)
    }

    var displaysTime: Bool {
        guard !fullday else { return false }
        var calendar = Calendar.current
        calendar.timeZone = displayTimeZone
        return calendar.startOfDay(for: start) != start || calendar.startOfDay(for: end) != end
    }

    private var displayTimeZone: TimeZone {
        return fullday ? TimeZone(identifier: "UTC") ?? .current : .current
    }

    func chipDescription(now: Date) -> String {
        if state(at: now) == .ongoing {
            return MailResourcesStrings.Localizable.scheduledAbsenceChipOngoing(formattedReturnDate(now: now))
        }
        return MailResourcesStrings.Localizable.scheduledAbsenceChipUpcoming(formattedStart(now: now), formattedEnd(now: now))
    }

    private func format(_ date: Date, style: Date.FormatStyle = .scheduledAbsenceDay, now: Date) -> String {
        var style = displaysTime ? style.hour().minute() : style
        style.timeZone = displayTimeZone
        return date.formatted(.yearIfNeeded(style, now: now))
    }
}
