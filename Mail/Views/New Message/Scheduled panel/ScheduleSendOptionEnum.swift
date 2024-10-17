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

import SwiftUI
import MailResources

enum ScheduleSendOption: String, Identifiable {
    case thisAfternoon
    case thisEvening
    case tomorrowMorning
    case nextWeekMorning
    case nextWeekAfternoon

    var id: Self { self }

    var date: Date? {
        switch self {
        case .thisAfternoon:
            return dateFromNow(hour: 14, of: (.day, 0))
        case .thisEvening:
            return dateFromNow(hour: 18, of: (.day, 0))
        case .tomorrowMorning:
            return dateFromNow(hour: 8, of: (.day, 1))
        case .nextWeekMorning:
            return dateFromNow(hour: 8, of: (.weekday, 1))
        case .nextWeekAfternoon:
            return dateFromNow(hour: 18, of: (.weekday, 1))
        }
    }

    var title: String {
        switch self {
        case .thisAfternoon:
            return "thisAfternoon"
        case .thisEvening:
            return "thisEvening"
        case .tomorrowMorning:
            return "tomorrowMorning"
        case .nextWeekMorning:
            return "nextWeekMorning"
        case .nextWeekAfternoon:
            return "nextWeekAfternoon"
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
        case .nextWeekMorning:
            return MailResourcesAsset.nextWeek.swiftUIImage
        case .nextWeekAfternoon:
            return MailResourcesAsset.nextWeek.swiftUIImage
        }
    }

    private func dateFromNow(hour: Int, of: (Calendar.Component, Int)) -> Date? {
        let calendar = Calendar.current
        if let startDate = calendar.date(byAdding: of.0, value: of.1, to: .now) {
            return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startDate)
        }
        return nil
    }
}
