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

struct SettingsOptionCell: View {
    let title: String
    let icon: Image?
    let hint: String?
    let isSelected: Bool
    let isLast: Bool
    let action: () -> Void

    init(
        title: String,
        icon: Image? = nil,
        hint: String? = nil,
        isSelected: Bool = false,
        isLast: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.hint = hint
        self.isSelected = isSelected
        self.isLast = isLast
        self.action = action
    }

    init(value: any SettingsOptionEnum, isSelected: Bool, isLast: Bool, action: @escaping () -> Void) {
        self.init(title: value.title, icon: value.image, hint: value.hint, isSelected: isSelected, isLast: isLast, action: action)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: UIPadding.regular) {
                    VStack(alignment: .leading, spacing: UIPadding.small) {
                        HStack(spacing: UIPadding.regular) {
                            icon?
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(MailResourcesAsset.textTertiaryColor)

                            Text(title)
                                .textStyle(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if isSelected {
                            if let hint {
                                Text(hint)
                                    .textStyle(.bodySmallSecondary)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                    if isSelected {
                        IKIcon(MailResourcesAsset.check)
                            .foregroundStyle(.tint)
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

#Preview("With hint") {
    SettingsOptionCell(value: AutoAdvance.naturalThread, isSelected: true, isLast: true) {
        /* Preview */
    }
}
