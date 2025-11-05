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

import DesignSystem
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailCoreUI
import SwiftUI

struct ScheduleOptionView: View {
    @Environment(\.dismiss) private var dismiss

    let type: ScheduleType
    let option: ScheduleOption
    let completionHandler: (Date) -> Void

    var body: some View {
        if let scheduleDate = option.date {
            Button(action: didTapOption) {
                HStack(spacing: IKPadding.medium) {
                    option.icon
                        .iconSize(.large)

                    Text(option.title)
                        .textStyle(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(scheduleDate, format: .scheduleOption)
                        .textStyle(.bodySmallSecondary)
                }
            }
            .padding(value: .medium)
        }
    }

    private func didTapOption() {
        guard let scheduleDate = option.date else { return }

        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: type.matomoCategory, name: option.matomoName)
        completionHandler(scheduleDate)
        dismiss()
    }
}

#Preview {
    ScheduleOptionView(type: .scheduledDraft, option: .nextMondayAfternoon) { date in
        print("Button \(date.formatted(.scheduleOption)) clicked !")
    }
    ScheduleOptionView(type: .snooze, option: .lastSchedule(value: .now)) { date in
        print("Button \(date.formatted(.scheduleOption)) clicked !")
    }
    ScheduleOptionView(type: .scheduledDraft, option: .thisAfternoon) { date in
        print("Button \(date.formatted(.scheduleOption)) clicked !")
    }
}
