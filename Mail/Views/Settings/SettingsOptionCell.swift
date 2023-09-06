/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import MailCore
import MailResources
import SwiftUI

struct SettingsOptionCell<OptionEnum>: View where OptionEnum: SettingsOptionEnum {
    let value: OptionEnum
    let isSelected: Bool
    let isLast: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: UIPadding.regular) {
                    value.image?
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(MailResourcesAsset.textTertiaryColor)

                    Text(value.title)
                        .textStyle(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
                .settingsItem()

                if !isLast {
                    IKDivider()
                }
            }
        }
        .settingsCell()
    }
}

#Preview {
    SettingsOptionCell(value: ThreadMode.conversation, isSelected: false, isLast: false) {
        /* Preview */
    }
}
