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

import MailCoreUI
import MailResources
import SwiftUI

struct ScheduleCell: View {
    let option: ScheduleOption
    let isSelected: Bool
    var showUpgradeChip = false
    let action: () -> Void

    private var shouldShowDate: Bool {
        if option.isCustom {
            return isSelected && option.date != nil
        }
        return option.date != nil
    }

    var body: some View {
        SelectableRow(
            title: option.title,
            isSelected: isSelected,
            showUpgradeChip: showUpgradeChip,
            showChevron: option.isCustom && !isSelected,
            action: action
        ) {
            if shouldShowDate, let date = option.date {
                Text(date, format: .scheduleOption)
                    .textStyle(.bodySmallSecondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        ScheduleCell(option: .thisAfternoon, isSelected: false) {}
        IKDivider(type: .item)
        ScheduleCell(option: .thisEvening, isSelected: true) {}
        IKDivider(type: .item)
        ScheduleCell(option: .tomorrowMorning, isSelected: false) {}
        IKDivider(type: .item)
        ScheduleCell(option: .custom(date: .now), isSelected: false, showUpgradeChip: true) {}
    }
}
