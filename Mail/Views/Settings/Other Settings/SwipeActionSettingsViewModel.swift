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

import Foundation
import MailCore
import MailResources
import SwiftUI

@MainActor class SwipeActionSettingsViewModel: SettingsViewModel {
    init() {
        super.init(title: MailResourcesStrings.settingsSwipeActionsTitle)
        sections = [.rightSwipe, .leftSwipe]
    }

    override func updateSelectedValue() {
        selectedValues = [
            .swipeShortRightOption: UserDefaults.shared.swipeShortRight,
            .swipeLongRightOption: UserDefaults.shared.swipeLongRight,
            .swipeShortLeftOption: UserDefaults.shared.swipeShortLeft,
            .swipeLongLeftOption: UserDefaults.shared.swipeLongLeft
        ]
    }
}

extension SettingsSection {
    static let rightSwipe = SettingsSection(
        id: 1,
        name: "",
        items: [.shortRight, .longRight]
    )
    static let leftSwipe = SettingsSection(
        id: 2,
        name: "",
        items: [.shortLeft, .longLeft]
    )
}

private extension SettingsItem {
    static let shortRight = SettingsItem(
        id: 1,
        title: MailResourcesStrings.settingsSwipeShortRight,
        type: .option(.swipeShortRightOption)
    )
    static let longRight = SettingsItem(
        id: 2,
        title: MailResourcesStrings.settingsSwipeLongRight,
        type: .option(.swipeLongRightOption)
    )

    static let shortLeft = SettingsItem(
        id: 3,
        title: MailResourcesStrings.settingsSwipeShortLeft,
        type: .option(.swipeShortLeftOption)
    )
    static let longLeft = SettingsItem(
        id: 4,
        title: MailResourcesStrings.settingsSwipeLongLeft,
        type: .option(.swipeLongLeftOption)
    )
}
