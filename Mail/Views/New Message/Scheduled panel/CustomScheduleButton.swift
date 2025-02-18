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
import MailCore
import MailCoreUI
import MailResources
import MyKSuite
import SwiftUI

struct CustomScheduleButton: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var customSchedule: Bool
    @Binding var isShowingMyKSuiteUpgrade: Bool

    let isMyKSuiteStandard: Bool

    var body: some View {
        Button(action: showCustomSchedulePicker) {
            HStack(spacing: IKPadding.medium) {
                MailResourcesAsset.pencil
                    .iconSize(.large)

                Text(MailResourcesStrings.Localizable.buttonCustomSchedule)
                    .textStyle(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isMyKSuiteStandard {
                    MyKSuitePlusChip()
                }

                ChevronIcon(direction: .right, shapeStyle: MailResourcesAsset.textSecondaryColor.swiftUIColor)
            }
        }
        .padding(value: .medium)
    }

    private func showCustomSchedulePicker() {
        if isMyKSuiteStandard {
            isShowingMyKSuiteUpgrade = true
        } else {
            customSchedule = true
        }
        dismiss()
    }
}
