/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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
import InfomaniakCoreCommonUI

enum ScheduleType: Sendable {
    case scheduledDraft
    case snooze

    var matomoCategory: MatomoUtils.EventCategory {
        switch self {
        case .scheduledDraft:
            return .scheduleSend
        case .snooze:
            return .snooze
        }
    }

    var lastCustomScheduleDateKeyPath: ReferenceWritableKeyPath<UserDefaults, Date> {
        switch self {
        case .scheduledDraft:
            return \.lastCustomScheduledDraftDate
        case .snooze:
            return \.lastCustomSnoozeDate
        }
    }
}

// MARK: - Minimum and maximum date

extension ScheduleType {
    var minimumInterval: TimeInterval {
        return 60 * 5 // 5 minutes
    }

    var maximumInterval: TimeInterval {
        switch self {
        case .scheduledDraft:
            return 60 * 60 * 24 * 365 * 10 // 10 years
        case .snooze:
            return 60 * 60 * 24 * 365 // 1 year
        }
    }

    var minimumDate: Date {
        return .now.addingTimeInterval(minimumInterval)
    }

    var maximumDate: Date {
        return .now.addingTimeInterval(maximumInterval)
    }

    func isDateInValidTimeframe(_ date: Date) -> Bool {
        let minimumDateDelta = Calendar.current.compare(date, to: minimumDate, toGranularity: .minute)
        let isTooEarly = minimumDateDelta == .orderedAscending

        let maximumDateDelta = Calendar.current.compare(date, to: maximumDate, toGranularity: .minute)
        let isTooLate = maximumDateDelta == .orderedDescending

        return !isTooEarly && !isTooLate
    }
}
