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

enum ReminderOption: Identifiable, Equatable {
    case oneDay
    case threeDays
    case sevenDays
    case custom(date: Date)

    static let presetCases: [ReminderOption] = [.oneDay, .threeDays, .sevenDays]

    var id: String { title }

    var title: String {
        switch self {
        case .oneDay:
            return MailResourcesStrings.Localizable.hoursBeforeSendingReminder(24)
        case .threeDays:
            return MailResourcesStrings.Localizable.daysBeforeSendingReminder(3)
        case .sevenDays:
            return MailResourcesStrings.Localizable.daysBeforeSendingReminder(7)
        case .custom:
            return MailResourcesStrings.Localizable.buttonCustomSchedule
        }
    }

    var date: Date? {
        if case .custom(let date) = self {
            return date
        }
        return nil
    }

    func reminderDate(sentAt sendDate: Date) -> Date? {
        switch self {
        case .oneDay:
            return Calendar.current.date(byAdding: .day, value: 1, to: sendDate)
        case .threeDays:
            return Calendar.current.date(byAdding: .day, value: 3, to: sendDate)
        case .sevenDays:
            return Calendar.current.date(byAdding: .day, value: 7, to: sendDate)
        case .custom(let date):
            return date
        }
    }

    var isCustom: Bool {
        if case .custom = self {
            return true
        }
        return false
    }
}
