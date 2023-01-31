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
    @AppStorage(UserDefaults.shared.key(.swipeShortRight)) var shortRight = SwipeAction.none
    @AppStorage(UserDefaults.shared.key(.swipeLongRight)) var longRight = SwipeAction.none
    @AppStorage(UserDefaults.shared.key(.swipeShortLeft)) var shortLeft = SwipeAction.none
    @AppStorage(UserDefaults.shared.key(.swipeLongLeft)) var longLeft = SwipeAction.none

    var section: SwipeSettingsSection

    var actions: [SwipeAction] {
        return section == .rightSwipe ? [longRight, shortRight] : [shortLeft, longLeft]
    }

    var body: some View {
        HStack(spacing: 0) {
            if section != .rightSwipe {
                SkeletonSwipeCell(isLeading: false)
            }

            ForEach(actions.indices, id: \.self) { i in
                let action = actions[i]
                ZStack {
                    if action == .none {
                        if i == 0 {
                            MailResourcesAsset.separatorColor.swiftUiColor
                        } else {
                            MailResourcesAsset.grayActionColor.swiftUiColor
                        }

                        Text(MailResourcesStrings.Localizable.settingsSwipeActionToDefine)
                            .textStyle(.bodySmallSecondary)
                    } else {
                        action.swipeTint
                        action.swipeIcon?
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(MailResourcesAsset.onAccentColor)
                    }
                }
                .frame(width: 80)
            }

            if section == .rightSwipe {
                SkeletonSwipeCell(isLeading: true)
            }
        }
        .cornerRadius(15)
        .frame(height: 80)
        .background(
            MailResourcesAsset.backgroundColor.swiftUiColor
                .cornerRadius(15)
                .shadow(radius: 4)
        )
    }
}

struct SwipeConfigCell_Previews: PreviewProvider {
    static var previews: some View {
        SwipeConfigCell(section: .rightSwipe)
            .previewDisplayName("Swipe Right")

        SwipeConfigCell(section: .leftSwipe)
            .previewDisplayName("Swipe Left")
    }
}
