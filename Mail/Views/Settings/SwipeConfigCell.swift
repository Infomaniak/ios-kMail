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
    @Binding var selectedValues: [SettingsOption: SettingsOptionEnum]
    var section: SettingsSection

    var actions: [SwipeAction] {
        var newActions = [SwipeAction]()
        if section == .rightSwipe {
            if let action = selectedValues[.swipeLongRightOption] as? SwipeAction {
                newActions.append(action)
            }
            if let action = selectedValues[.swipeShortRightOption] as? SwipeAction {
                newActions.append(action)
            }
        } else if section == .leftSwipe {
            if let action = selectedValues[.swipeLongLeftOption] as? SwipeAction {
                newActions.append(action)
            }
            if let action = selectedValues[.swipeShortLeftOption] as? SwipeAction {
                newActions.append(action)
            }
        }
        return newActions
    }

    var body: some View {
        HStack(spacing: 0) {
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
                            .textStyle(.calloutSecondary)
                    } else {
                        action.swipeTint

                        action.swipeIcon?
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(MailResourcesAsset.onAccentColor)
                    }
                }
                .frame(width: 74)
            }

            Image(resource: MailResourcesAsset.configSwipe)
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
        .frame(height: 80)
        .environment(\.layoutDirection, section == .rightSwipe ? .leftToRight : .rightToLeft)
        .offset(x: section == .rightSwipe ? 0 : CGFloat(-80 * actions.count), y: 0)
    }
}

struct SwipeConfigCell_Previews: PreviewProvider {
    static var previews: some View {
        SwipeConfigCell(selectedValues: .constant([.swipeLongRightOption: SwipeAction.readUnread]), section: .rightSwipe)
        SwipeConfigCell(selectedValues: .constant([.swipeLongRightOption: SwipeAction.readUnread, .swipeShortRightOption: SwipeAction.archive]), section: .rightSwipe)
        SwipeConfigCell(selectedValues: .constant([.swipeLongLeftOption: SwipeAction.delete]), section: .leftSwipe)
        SwipeConfigCell(selectedValues: .constant([.swipeLongLeftOption: SwipeAction.delete, .swipeShortLeftOption: SwipeAction.quickAction]), section: .leftSwipe)
    }
}
