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

import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import SwiftUI

struct ScheduleOptionView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @Environment(\.dismiss) private var dismiss

    let option: ScheduleSendOption
    let setScheduleAction: (Date) -> Void

    let dateFormat = Date.FormatStyle.dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute()

    var body: some View {
        if let scheduleDate = option.date {
            Button {
                matomo.track(eventWithCategory: .scheduleSend, name: option.matomoName)
                setScheduleAction(scheduleDate)
                dismiss()
            } label: {
                HStack {
                    Label {
                        Text(option.title)
                            .textStyle(.body)
                    } icon: {
                        option.icon
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .labelStyle(.ikLabel(IKPadding.medium))

                    Text(scheduleDate.formatted(dateFormat))
                        .textStyle(.bodySmallSecondary)
                }
            }
            .padding(.vertical, value: .small)
        }
    }
}

#Preview {
    ScheduleOptionView(option: .nextMondayAfternoon) { date in
        print("Button \(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute())) clicked !")
    }
    ScheduleOptionView(option: .lastSchedule(value: .now)) { date in
        print("Button \(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute())) clicked !")
    }
    ScheduleOptionView(option: .thisAfternoon) { date in
        print("Button \(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute())) clicked !")
    }
}
