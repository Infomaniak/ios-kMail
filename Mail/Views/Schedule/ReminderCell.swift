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
import MailCoreUI
import MailResources
import SwiftUI

struct ReminderCell: View {
    let option: ReminderOption
    let isSelected: Bool
    var showUpgradeChip = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: IKPadding.micro) {
                    Text(option.title)
                        .textStyle(.body)

                    if option.isCustom {
                        if isSelected, let subtitle = option.subtitle {
                            Text(subtitle)
                                .textStyle(.bodySmallSecondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    MailResourcesAsset.check.iconSize(.medium)
                        .foregroundStyle(Color.accentColor)
                }

                if showUpgradeChip {
                    MyKSuitePlusChip()
                } else if option.isCustom, !isSelected {
                    ChevronIcon(direction: .right, shapeStyle: MailResourcesAsset.textSecondaryColor.swiftUIColor)
                }
            }
            .padding(.leading, IKIconSize.large.rawValue + IKPadding.mini)
            .padding(.trailing, value: .medium)
        }
        .padding(.vertical, value: .medium)
        .padding(.leading, value: .medium)
    }
}

#Preview {
    VStack(spacing: 0) {
        ReminderCell(option: .oneDay, isSelected: false) {}
        IKDivider(type: .item)
        ReminderCell(option: .threeDays, isSelected: true) {}
        IKDivider(type: .item)
        ReminderCell(option: .sevenDays, isSelected: false) {}
        IKDivider(type: .item)
        ReminderCell(option: .customHours(5), isSelected: true) {}
        IKDivider(type: .item)
        ReminderCell(option: .custom, isSelected: false, showUpgradeChip: true) {}
    }
}
