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

extension ScheduleOption {
    static var allPresetOptions: [ScheduleOption] = [
        .laterThisMorning,
        .thisAfternoon,
        .thisEvening,
        .tomorrowMorning,
        .nextMonday,
        .nextMondayMorning,
        .nextMondayAfternoon
    ]
}

enum ScheduleOption: Identifiable, Equatable {
    case laterThisMorning
    case thisAfternoon
    case thisEvening
    case tomorrowMorning
    case nextMonday
    case nextMondayMorning
    case nextMondayAfternoon
    case lastSchedule(value: Date)

    var id: String { title }

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
            return MailResourcesAsset.clockCounterclockwise.swiftUIImage
        }
    }

    var matomoName: String {
        switch self {
        case .laterThisMorning:
            "laterThisMorning"
        case .thisAfternoon:
            "thisAfternoon"
        case .thisEvening:
            "thisEvening"
        case .tomorrowMorning:
            "tomorrowMorning"
        case .nextMonday:
            "nextMonday"
        case .nextMondayMorning:
            "nextMondayMorning"
        case .nextMondayAfternoon:
            "nextMondayAfternoon"
        case .lastSchedule:
            "lastSelectedSchedule"
        }
    }

    var date: Date? {
        switch self {
        case .laterThisMorning:
            return specificHour(at: 8, from: .now)
        case .thisAfternoon:
            return specificHour(at: 14, from: .now)
        case .thisEvening:
            return specificHour(at: 18, from: .now)
        case .tomorrowMorning:
            return specificHour(at: 8, from: .tomorrow)
        case .nextMonday, .nextMondayMorning:
            return nextMonday(at: 8)
        case .nextMondayAfternoon:
            return nextMonday(at: 14)
        case .lastSchedule(let date):
            return date
        }
    }

    var canBeDisplayed: Bool {
        guard let date else { return false }
        return isAvailable && date >= .minimumScheduleDelay
    }

    private var isAvailable: Bool {
        let isInWeekend = Calendar.current.isDateInWeekend(.now)

        switch self {
        case .laterThisMorning, .thisAfternoon, .thisEvening, .tomorrowMorning, .nextMonday:
            return !isInWeekend
        case .nextMondayMorning, .nextMondayAfternoon:
            return isInWeekend
        case .lastSchedule:
            return true
        }
    }

    private func specificHour(at hour: Int, from date: Date) -> Date? {
        return Calendar.current.date(bySetting: .hour, value: hour, of: date.startOfDay)
    }

    private func nextMonday(at hour: Int) -> Date? {
        let dateComponents = DateComponents(hour: hour, weekday: 2)
        return Calendar.current.nextDate(after: .now.startOfDay, matching: dateComponents, matchingPolicy: .nextTime)
    }
}
