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
import MailResources
import SwiftUI

struct CustomScheduleButton: View {
    @LazyInjectService private var featureFlagsManager: FeatureFlagsManageable

    @Environment(\.dismiss) private var dismiss

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
        if featureFlagsManager.isEnabled(.scheduleSendDraft) {
            customSchedule = true
        } else {
            isShowingDiscovery = true
        }
        dismiss()
    }
}
