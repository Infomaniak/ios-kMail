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

import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCoreUI
import RealmSwift
import SwiftUI

struct ScheduleFloatingPanelView: View {
    @Binding var customSchedule: Bool
    @Binding var isShowingDiscovery: Bool

    let isFree: Bool
    let lastScheduleInterval: Double
    let setScheduleAction: (Date) -> Void

    private var scheduleOptions: [ScheduleSendOption] {
        var allSimpleCases = ScheduleSendOption.allSimpleCases
        allSimpleCases.insert(ScheduleSendOption.lastSchedule(value: Date(timeIntervalSince1970: lastScheduleInterval)), at: 0)
        return allSimpleCases.filter { $0.shouldBeDisplayedNow }
    }

    var body: some View {
        VStack(spacing: IKPadding.small) {
            ForEach(scheduleOptions) { option in
                ScheduleOptionView(option: option, setScheduleAction: setScheduleAction)

                IKDivider(type: .full)
            }
            CustomScheduleButton(
                customSchedule: $customSchedule,
                isShowingDiscovery: $isShowingDiscovery,
                isFree: isFree
            )
        }
        .padding(value: .medium)
    }
}
