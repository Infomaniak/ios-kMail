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
import SwiftUI

struct CustomScheduleButtonRow: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var customSchedule: Bool
    @Binding var isShowingDiscovery: Bool

    let isFree: Bool

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

                ChevronIcon(direction: .right, shapeStyle: MailResourcesAsset.textSecondaryColor.swiftUIColor)
            }
        }
        .padding(.vertical, value: .small)
    }

    private func showCustomSchedulePicker() {
        if isFree {
            isShowingDiscovery = true
        } else {
            customSchedule = true
        }
        dismiss()
    }
}
