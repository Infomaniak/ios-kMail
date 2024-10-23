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
    case nextWeekMorning
    case nextWeekAfternoon
    case lastSchedule(value: Date)

    var id: UUID { UUID() }

    var date: Date? {
        switch self {
        case .thisAfternoon:
            return dateFromNow(setHour: 14, addDay: 0, addWeek: 0)
        case .thisEvening:
            return dateFromNow(setHour: 18, addDay: 0, addWeek: 0)
        case .tomorrowMorning:
            return dateFromNow(setHour: 8, addDay: 1, addWeek: 0)
        case .nextWeekMorning:
            return dateFromNow(setHour: 8, addDay: 0, addWeek: 1)
        case .nextWeekAfternoon:
            return dateFromNow(setHour: 18, addDay: 0, addWeek: 1)
        case .lastSchedule(let value):
            return value
        }
    }

    var title: String {
        switch self {
        case .thisAfternoon:
            return "Cet après-midi"
        case .thisEvening:
            return "Ce soir"
        case .tomorrowMorning:
            return "Demain matin"
        case .nextWeekMorning:
            return "La semaine prochaine"
        case .nextWeekAfternoon:
            return "La semaine prochaine 2"
        case .lastSchedule:
            return "Dernier schedule"
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
        case .lastSchedule:
            return MailResourcesAsset.lastSchedule.swiftUIImage
        }
    }

    var iso8601: String? {
        guard let date = date else { return nil }
        return date.ISO8601Format().replacingOccurrences(of: "Z", with: "+00:00")
    }

    private func dateFromNow(setHour: Int, addDay: Int, addWeek: Int) -> Date? {
        guard let dateWithHour = Calendar.current.date(bySetting: .hour, value: setHour, of: .now) else { return nil }
        guard let dateWithDay = Calendar.current.date(byAdding: .day, value: addDay, to: dateWithHour) else { return nil }
        return Calendar.current.date(byAdding: .weekOfYear, value: addWeek, to: dateWithDay)
    }
}
