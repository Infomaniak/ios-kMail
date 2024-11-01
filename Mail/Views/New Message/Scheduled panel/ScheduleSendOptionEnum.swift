/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import MailResources
import SwiftUI

enum ScheduleSendOption: Identifiable, Equatable {
    case thisAfternoon
    case thisEvening
    case tomorrowMorning
    case nextMondayMorning
    case nextMondayAfternoon
    case lastSchedule(value: Date)

    var id: UUID { UUID() }

    var date: Date? {
        switch self {
        case .thisAfternoon:
            return dateFromNow(setHour: 14)
        case .thisEvening:
            return dateFromNow(setHour: 18)
        case .tomorrowMorning:
            return dateFromNow(setHour: 8, tomorrow: true)
        case .nextMondayMorning:
            return nextMonday(setHour: 8)
        case .nextMondayAfternoon:
            return nextMonday(setHour: 14)
        case .lastSchedule(let value):
            return value
        }
    }

    var title: String {
        switch self {
        case .thisAfternoon:
            return MailResourcesStrings.Localizable.thisAfternoon
        case .thisEvening:
            return MailResourcesStrings.Localizable.thisEvening
        case .tomorrowMorning:
            return MailResourcesStrings.Localizable.tomorrowMorning
        case .nextMondayMorning:
            return MailResourcesStrings.Localizable.nextMondayMorning
        case .nextMondayAfternoon:
            return MailResourcesStrings.Localizable.nextMondayAfternoon
        case .lastSchedule:
            return MailResourcesStrings.Localizable.lastSelectedSchedule
        }
    }

    var icon: Image {
        switch self {
        case .thisAfternoon:
            return MailResourcesAsset.todayAfternoon.swiftUIImage
        case .thisEvening:
            return MailResourcesAsset.todayEvening.swiftUIImage
        case .tomorrowMorning:
            return MailResourcesAsset.tomorrowMorning.swiftUIImage
        case .nextMondayMorning:
            return MailResourcesAsset.nextWeek.swiftUIImage
        case .nextMondayAfternoon:
            return MailResourcesAsset.nextWeek.swiftUIImage
        case .lastSchedule:
            return MailResourcesAsset.lastSchedule.swiftUIImage
        }
    }

    var iso8601: String? {
        guard let date else { return nil }
        return date.ISO8601WithTimeZone
    }

    private func dateFromNow(setHour: Int, tomorrow: Bool = false) -> Date? {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        guard let dateWithDay = Calendar.current.date(byAdding: .day, value: tomorrow ? 1 : 0, to: startOfDay) else { return nil }
        return Calendar.current.date(bySetting: .hour, value: setHour, of: dateWithDay)
    }

    private func nextMonday(setHour: Int) -> Date? {
        let todayMidDay = Calendar.current.startOfDay(for: .now).addingTimeInterval(43200)
        print(DateFormatter.localizedString(from: todayMidDay, dateStyle: .medium, timeStyle: .medium))
        return Calendar.current.nextDate(
            after: todayMidDay,
            matching: .init(hour: setHour, weekday: 2),
            matchingPolicy: .nextTime,
            direction: .forward
        )
    }
}
