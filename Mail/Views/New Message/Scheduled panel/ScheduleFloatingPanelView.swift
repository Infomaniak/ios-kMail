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

    @ObservedRealmObject var draft: Draft

    @Binding var isPresented: Bool
    @Binding var customSchedule: Bool
    @Binding var isShowingDiscovery: Bool

    let lastScheduleInterval: Double
    let dismissMessageView: () -> Void
    let setScheduleAction: (Date) -> Void

    var isWeekend: Bool {
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
            if lastScheduleInterval > Date.now.timeIntervalSince1970 + 5 * 60 {
                ScheduleOptionButton(
                    option: .lastSchedule(value: Date(timeIntervalSince1970: lastScheduleInterval)),
                    setScheduleAction: setScheduleAction
                )
                IKDivider(type: .full)
            }
            ForEach(scheduleOptions) { option in
                ScheduleOptionButton(option: option, setScheduleAction: setScheduleAction)
                IKDivider(type: .full)
            }
            CustomScheduleButton(
                isPresented: $isPresented,
                customSchedule: $customSchedule,
                isShowingDiscovery: $isShowingDiscovery
            )
        }
        .padding(.horizontal, value: .medium)
    }
}

struct CustomScheduleButton: View {
    @LazyInjectService private var featureFlagsManager: FeatureFlagsManageable

    @Binding var isPresented: Bool
    @Binding var customSchedule: Bool
    @Binding var isShowingDiscovery: Bool

    var body: some View {
        Button(action: showCustomSchedulePicker) {
            HStack {
                Label {
                    Text(MailResourcesStrings.Localizable.buttonCustomSchedule)
                        .textStyle(.body)
                } icon: {
                    MailResourcesAsset.customSchedule.swiftUIImage
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                MailResourcesAsset.chevronRight.swiftUIImage
            }
        }
        .padding(.vertical, value: .small)
    }

    func showCustomSchedulePicker() {
        isPresented = false
        if featureFlagsManager.isEnabled(.scheduleSendDraft) {
            customSchedule = true
        } else {
            isShowingDiscovery = true
        }
    }
}

struct ScheduleOptionButton: View {
    let option: ScheduleSendOption
    let setScheduleAction: (Date) -> Void

    var body: some View {
        Button(action: {
            if let formatDate = option.date {
                setScheduleAction(formatDate)
            }
        }, label: {
            ScheduleFloatingPanelRow(
                title: option.title,
                icon: option.icon,
                scheduleDate: option.date
            )
        })
        .padding(.vertical, value: .small)
    }
}
