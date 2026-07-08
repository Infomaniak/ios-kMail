/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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
import MailCoreUI
import RealmSwift
import SwiftUI

struct ReminderFloatingPanelView: View {
    @Binding var isShowingCustomReminderAlert: Bool
    @Binding var isShowingMyKSuiteUpgrade: Bool
    @Binding var isShowingKSuiteProUpgrade: Bool
    @Binding var isShowingMailPremiumUpgrade: Bool

    let completionHandler: (ReminderOption) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(ReminderOption.presetCases, id: \.self) { option in
                ReminderCell(
                    option: option,
                    isSelected: false,
                    showPaddingLeft: false
                ) {
                    completionHandler(option)
                }
            }

            CustomScheduleButton(
                isShowingCustomAlert: $isShowingCustomReminderAlert,
                isShowingMyKSuiteUpgrade: $isShowingMyKSuiteUpgrade,
                isShowingKSuiteProUpgrade: $isShowingKSuiteProUpgrade,
                isShowingMailPremiumUpgrade: $isShowingMailPremiumUpgrade,
                type: .reminder(type: .option)
            )
        }
    }
}

#Preview {
    ReminderFloatingPanelView(
        isShowingCustomReminderAlert: .constant(false),
        isShowingMyKSuiteUpgrade: .constant(false),
        isShowingKSuiteProUpgrade: .constant(false),
        isShowingMailPremiumUpgrade: .constant(false)
    ) { _ in }
}
