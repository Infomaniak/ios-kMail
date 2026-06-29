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
import MailResources

enum ReminderOption: Hashable {
    case oneDay
    case threeDays
    case sevenDays
    case custom
    case customHours(Int)
    case customDays(Int)

    static let presetCases: [ReminderOption] = [.oneDay, .threeDays, .sevenDays]

    var title: String {
        switch self {
        case .oneDay:
            return MailResourcesStrings.Localizable.hoursBeforeSendingReminderPlural(24)
        case .threeDays:
            return MailResourcesStrings.Localizable.daysBeforeSendingReminderPlural(3)
        case .sevenDays:
            return MailResourcesStrings.Localizable.daysBeforeSendingReminderPlural(7)
        case .custom, .customHours, .customDays:
            return MailResourcesStrings.Localizable.buttonCustomReminder
        }
    }

    var subtitle: String? {
        switch self {
        case .customHours(let value):
            if value > 1 {
                return MailResourcesStrings.Localizable.hoursBeforeSendingReminderPlural(value)
            }
            return MailResourcesStrings.Localizable.hoursBeforeSendingReminder(value)
        case .customDays(let value):
            if value > 1 {
                return MailResourcesStrings.Localizable.daysBeforeSendingReminderPlural(value)
            }
            return MailResourcesStrings.Localizable.daysBeforeSendingReminder(value)
        case .oneDay, .threeDays, .sevenDays, .custom:
            return nil
        }
    }

    var isCustom: Bool {
        switch self {
        case .custom, .customHours, .customDays:
            return true
        case .oneDay, .threeDays, .sevenDays:
            return false
        }
    }

    func reminderDate(sentAt sendDate: Date) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .oneDay:
            return calendar.date(byAdding: .day, value: 1, to: sendDate)
        case .threeDays:
            return calendar.date(byAdding: .day, value: 3, to: sendDate)
        case .sevenDays:
            return calendar.date(byAdding: .day, value: 7, to: sendDate)
        case .customHours(let value):
            return calendar.date(byAdding: .hour, value: value, to: sendDate)
        case .customDays(let value):
            return calendar.date(byAdding: .day, value: value, to: sendDate)
        case .custom:
            return nil
        }
    }

    /// Unit for custom reminder picker
    enum CustomUnit: CaseIterable {
        case hours
        case days

        var range: ClosedRange<Int> {
            switch self {
            case .hours: return 1 ... 23
            case .days: return 1 ... 30
            }
        }

        func title(for value: Int) -> String {
            switch self {
            case .hours:
                if value > 1 {
                    return MailResourcesStrings.Localizable.unitHoursPlural
                }
                return MailResourcesStrings.Localizable.unitHours
            case .days:
                if value > 1 {
                    return MailResourcesStrings.Localizable.unitDaysPlural
                }
                return MailResourcesStrings.Localizable.unitDays
            }
        }

        func makeOption(value: Int) -> ReminderOption {
            let clamped = min(max(value, range.lowerBound), range.upperBound)
            return self == .hours ? .customHours(clamped) : .customDays(clamped)
        }
    }
}
