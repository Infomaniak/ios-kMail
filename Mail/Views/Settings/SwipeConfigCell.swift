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

struct SwipeConfigCell: View {
    @State var selectedValues: [SettingsOption: SettingsOptionEnum]
    var section: SettingsSection

    private var offsetCount = 0

    init(selectedValues: [SettingsOption: SettingsOptionEnum], section: SettingsSection) {
        self.selectedValues = selectedValues
        self.section = section

        if section == .leftSwipe {
            if SwipeType.shortLeft.setting.swipeIcon != nil {
                offsetCount += 1
            }
            if SwipeType.longLeft.setting.swipeIcon != nil {
                offsetCount += 1
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            if section == .rightSwipe {
                SwipeType.longRight.setting.swipeIcon
                    .frame(width: 80, height: 80)
                    .background(Color(uiColor: SwipeType.longRight.setting.swipeTint ?? .clear))
                SwipeType.shortRight.setting.swipeIcon
                    .frame(width: 80, height: 80)
                    .background(Color(uiColor: SwipeType.shortRight.setting.swipeTint ?? .clear))
            }

            Image(uiImage: MailResourcesAsset.configSwipe.image)

            if section == .leftSwipe {
                SwipeType.shortLeft.setting.swipeIcon
                    .frame(width: 80, height: 80)
                    .background(Color(uiColor: SwipeType.shortLeft.setting.swipeTint ?? .clear))

                SwipeType.longLeft.setting.swipeIcon
                    .frame(width: 80, height: 80)
                    .background(Color(uiColor: SwipeType.longLeft.setting.swipeTint ?? .clear))
            }
        }
        .offset(x: CGFloat(-80 * offsetCount), y: 0)
    }
}

struct SwipeConfigCell_Previews: PreviewProvider {
    static var previews: some View {
        SwipeConfigCell(selectedValues: [:], section: .rightSwipe)
    }
}
