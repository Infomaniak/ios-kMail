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

import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct ScheduleFloatingPanelView: View {
    @Binding var isPresented: Bool
    @Binding var customSchedule: Bool

    let lastSchedule: Date?
    let hasScheduleSendEnabled = true

    private var scheduleOptions: [ScheduleSendOption] {
        guard !isWeekend() else { return [.nextWeekMorning, .nextWeekAfternoon] }

        switch Calendar.current.component(.hour, from: Date.now) {
        case 0 ... 13:
            return [.thisAfternoon, .tomorrowMorning, .nextWeekMorning]
        case 14 ... 19:
            return [.thisEvening, .tomorrowMorning, .nextWeekMorning]
        case 20 ... 23:
            return [.tomorrowMorning, .nextWeekMorning]
        default:
            return []
        }
    }

    var body: some View {
        VStack {
            Text("Schedule Send")
                .font(.title3)
            if let lastSchedule {
                Button(action: { print("Ziz") }) {
                    ScheduleFloatingPanelRow(
                        title: "Dernier horaire choisi",
                        icon: MailResourcesAsset.lastSchedule.swiftUIImage,
                        scheduleDate: lastSchedule
                    )
                }
                .padding(.vertical, value: .small)
                .padding(.horizontal, value: .medium)
                IKDivider()
            }
            ForEach(scheduleOptions) { option in
                Button(action: { print("oui") }, label: {
                    ScheduleFloatingPanelRow(
                        title: option.title,
                        icon: option.icon,
                        scheduleDate: option.date
                    )
                })
                .padding(.vertical, value: .small)
                .padding(.horizontal, value: .medium)
                IKDivider()
            }
            if hasScheduleSendEnabled {
                Button(action: {
                    isPresented = false
                    customSchedule = true
                }) {
                    HStack {
                        Label {
                            Text("Horaire personnalisé")
                        } icon: {
                            MailResourcesAsset.customSchedule.swiftUIImage
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "chevron.right")
                    }
                    .font(MailTextStyle.bodySmall.font)
                }
                .padding(.vertical, value: .small)
                .padding(.horizontal, value: .medium)
            }
        }
    }

    func isWeekend() -> Bool {
        [1, 7].contains(Calendar.current.component(.weekday, from: Date.now))
    }

    func setSchedule(scheduleDate: Date) {
        print("setSchedule")
    }
}
