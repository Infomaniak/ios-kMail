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
import Network
import SwiftUI

@MainActor class GeneralSettingsViewModel: SettingsViewModel {
    init() {
        super.init(title: MailResourcesStrings.settingsTitle)
        sections = [.emailAddresses, .general, .appearance]
    }

    override func updateSelectedValue() {
        selectedValues = [
            .threadDensityOption: UserDefaults.shared.threadDensity,
            .themeOption: UserDefaults.shared.theme,
            .displayModeOption: UserDefaults.shared.threadMode,
            .externalContentOption: UserDefaults.shared.displayExternalContent
        ]
    }
}

private extension SettingsSection {
    static let emailAddresses = SettingsSection(
        id: 1,
        name: MailResourcesStrings.settingsSectionEmailAddresses,
        items: []
    )
    static let general = SettingsSection(
        id: 2,
        name: MailResourcesStrings.settingsSectionGeneral,
        items: [.send, .lock]
    )
    static let appearance = SettingsSection(
        id: 3,
        name: MailResourcesStrings.settingsSectionAppearance,
        items: [.threadDensity, .theme, .swipeActions, .displayMode, .externalContent]
    )
}

private extension SettingsItem {
    static let send = SettingsItem(
        id: 1,
        title: MailResourcesStrings.settingsSendTitle,
        type: .subMenu(destination: .send)
    )
    static let lock = SettingsItem(
        id: 2,
        title: MailResourcesStrings.settingsCodeLock,
        type: .toggle(userDefaults: \.isAppLockEnabled)
    )
    static let threadDensity = SettingsItem(
        id: 3,
        title: MailResourcesStrings.settingsThreadListDensityTitle,
        type: .option(.threadDensityOption)
    )
    static let theme = SettingsItem(
        id: 4,
        title: MailResourcesStrings.settingsTheme,
        type: .option(.themeOption)
    )
    static let swipeActions = SettingsItem(
        id: 5,
        title: MailResourcesStrings.settingsSwipeActionsTitle,
        type: .subMenu(destination: .swipe)
    )
    static let displayMode = SettingsItem(
        id: 6,
        title: MailResourcesStrings.settingsMessageDisplayTitle,
        type: .option(.displayModeOption)
    )
    static let externalContent = SettingsItem(
        id: 7,
        title: MailResourcesStrings.settingsExternalContentTitle,
        type: .option(.externalContentOption)
    )
}
