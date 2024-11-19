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

import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

struct ScheduleFloatingPanelView: View {
    @LazyInjectService private var draftManager: DraftManager

    @Binding var customSchedule: Bool
    @Binding var isShowingDiscovery: Bool

    @ObservedRealmObject var draft: Draft

    let isFree: Bool
    let lastScheduleInterval: Double
    let dismissMessageView: () -> Void
    let setScheduleAction: (Date) -> Void

    private var isWeekend: Bool {
        [1, 7].contains(Calendar.current.component(.weekday, from: Date.now))
    }

    private var scheduleOptions: [ScheduleSendOption] {
        guard !isWeekend else { return [.nextMondayMorning, .nextMondayAfternoon] }

        switch Calendar.current.component(.hour, from: Date.now) {
        case 0 ... 7:
            return [.laterThisMorning, .tomorrowMorning, .nextMondayMorning]
        case 8 ... 13:
            return [.thisAfternoon, .tomorrowMorning, .nextMondayMorning]
        case 14 ... 19:
            return [.thisEvening, .tomorrowMorning, .nextMondayMorning]
        case 20 ... 23:
            return [.tomorrowMorning, .nextMondayMorning]
        default:
            return []
        }
    }

    var body: some View {
        VStack {
            if lastScheduleInterval > Date.minimumScheduleDelay.timeIntervalSince1970 {
                ScheduleOptionButtonRow(
                    option: .lastSchedule(value: Date(timeIntervalSince1970: lastScheduleInterval)),
                    setScheduleAction: setScheduleAction
                )
            }
            ForEach(scheduleOptions) { option in
                ScheduleOptionButtonRow(option: option, setScheduleAction: setScheduleAction)
            }
            CustomScheduleButtonRow(
                customSchedule: $customSchedule,
                isShowingDiscovery: $isShowingDiscovery,
                isFree: isFree
            )
        }
        .padding(.horizontal, value: .medium)
    }
}
