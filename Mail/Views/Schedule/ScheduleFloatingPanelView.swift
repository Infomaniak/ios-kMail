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
import InfomaniakDI
import MailCoreUI
import RealmSwift
import SwiftUI

struct ScheduleFloatingPanelView: View {
    @Binding var isShowingCustomScheduleAlert: Bool
    @Binding var isShowingMyKSuiteUpgrade: Bool
    @Binding var isShowingKSuiteProUpgrade: Bool
    @Binding var isShowingMailPremiumUpgrade: Bool

    let type: ScheduleType
    let initialDate: Date?
    let completionHandler: (Date) -> Void

    private var scheduleOptions: [ScheduleOption] {
        var seenDateOptions = Set<Date>()
        if let initialDate {
            seenDateOptions.insert(initialDate)
        }

        var filteredOptions = ScheduleOption.allPresetOptions.filter { option in
            guard option.canBeDisplayed, let date = option.date else { return false }
            if seenDateOptions.contains(date) {
                return false
            } else {
                seenDateOptions.insert(date)
                return true
            }
        }

        let lastScheduledDate = UserDefaults.shared[keyPath: type.lastCustomScheduleDateKeyPath]
        let lastScheduledOption = ScheduleOption.lastSchedule(value: lastScheduledDate)
        if lastScheduledOption.canBeDisplayed, !seenDateOptions.contains(lastScheduledDate) {
            filteredOptions.insert(.lastSchedule(value: lastScheduledDate), at: 0)
        }

        return filteredOptions
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(scheduleOptions) { option in
                ScheduleOptionView(type: type, option: option, completionHandler: completionHandler)

                IKDivider(type: .item)
            }

            CustomScheduleButton(
                isShowingCustomScheduleAlert: $isShowingCustomScheduleAlert,
                isShowingMyKSuiteUpgrade: $isShowingMyKSuiteUpgrade,
                isShowingKSuiteProUpgrade: $isShowingKSuiteProUpgrade,
                isShowingMailPremiumUpgrade: $isShowingMailPremiumUpgrade,
                type: type
            )
        }
    }
}

#Preview {
    ScheduleFloatingPanelView(
        isShowingCustomScheduleAlert: .constant(false),
        isShowingMyKSuiteUpgrade: .constant(false),
        isShowingKSuiteProUpgrade: .constant(false),
        isShowingMailPremiumUpgrade: .constant(false),
        type: .scheduledDraft,
        initialDate: nil
    ) { _ in }
        .environmentObject(PreviewHelper.sampleMailboxManager)
}
