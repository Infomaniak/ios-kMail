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
    case laterThisMorning
    case thisAfternoon
    case thisEvening
    case tomorrowMorning
    case nextMonday
    case nextMondayMorning
    case nextMondayAfternoon
    case lastSchedule(value: Date)

    var id: UUID { UUID() }

    var date: Date? {
        switch self {
        case .laterThisMorning:
            return dateFromNow(setHour: 8)
        case .thisAfternoon:
            return dateFromNow(setHour: 14)
        case .thisEvening:
            return dateFromNow(setHour: 18)
        case .tomorrowMorning:
            return dateFromNow(setHour: 8, tomorrow: true)
        case .nextMondayMorning, .nextMonday:
            return nextMonday(setHour: 8)
        case .nextMondayAfternoon:
            return nextMonday(setHour: 14)
        case .lastSchedule(let value):
            return value
        }
    }

    var title: String {
        switch self {
        case .laterThisMorning:
            return MailResourcesStrings.Localizable.laterThisMorning
        case .thisAfternoon:
            return MailResourcesStrings.Localizable.thisAfternoon
        case .thisEvening:
            return MailResourcesStrings.Localizable.thisEvening
        case .tomorrowMorning:
            return MailResourcesStrings.Localizable.tomorrowMorning
        case .nextMonday:
            return MailResourcesStrings.Localizable.nextMonday
        case .nextMondayMorning:
            return MailResourcesStrings.Localizable.mondayMorning
        case .nextMondayAfternoon:
            return MailResourcesStrings.Localizable.mondayAfternoon
        case .lastSchedule:
            return MailResourcesStrings.Localizable.lastSelectedSchedule
        }
    }

    var icon: Image {
        switch self {
        case .laterThisMorning:
            return MailResourcesAsset.sunHorizon.swiftUIImage
        case .thisAfternoon:
            return MailResourcesAsset.sunFilledRighthalf.swiftUIImage
        case .thisEvening:
            return MailResourcesAsset.moon.swiftUIImage
        case .tomorrowMorning:
            return MailResourcesAsset.sun.swiftUIImage
        case .nextMonday:
            return MailResourcesAsset.arrowBackward.swiftUIImage
        case .nextMondayMorning:
            return MailResourcesAsset.sun.swiftUIImage
        case .nextMondayAfternoon:
            return MailResourcesAsset.sunFilledRighthalf.swiftUIImage
        case .lastSchedule:
            return MailResourcesAsset.clockArrowCounterclockwise.swiftUIImage
        }
    }

    private func dateFromNow(setHour: Int, tomorrow: Bool = false) -> Date? {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        guard let dateWithDay = Calendar.current.date(byAdding: .day, value: tomorrow ? 1 : 0, to: startOfDay) else { return nil }
        return Calendar.current.date(bySetting: .hour, value: setHour, of: dateWithDay)
    }

    private func nextMonday(setHour: Int) -> Date? {
        let todayMidDay = Calendar.current.startOfDay(for: .now).addingTimeInterval(43200)
        return Calendar.current.nextDate(
            after: todayMidDay,
            matching: .init(hour: setHour, weekday: 2),
            matchingPolicy: .nextTime,
            direction: .forward
        )
    }
}
