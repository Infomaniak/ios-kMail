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
        super.init(title: MailResourcesStrings.Localizable.settingsTitle)
        sections = [.emailAddresses, .general, .appearance]
    }

    override func updateSelectedValue() {
        selectedValues = [
            .threadDensityOption: UserDefaults.shared.threadDensity,
            .themeOption: UserDefaults.shared.theme,
            .accentColor: UserDefaults.shared.accentColor,
            .displayModeOption: UserDefaults.shared.threadMode,
            .externalContentOption: UserDefaults.shared.displayExternalContent
        ]
    }
}

private extension SettingsSection {
    private static func getEmailAddresses() -> [SettingsItem] {
        var result: [SettingsItem] = []

        for mailbox in AccountManager.instance.mailboxes {
            if let mailboxManager = AccountManager.instance.getMailboxManager(for: mailbox) {
                result.append(SettingsItem(
                    id: mailbox.mailboxId,
                    title: mailbox.email,
                    type: .subMenu(destination: .emailSettings(mailboxManager: mailboxManager))
                ))
            }
        }
        return result
    }

    static let emailAddresses = SettingsSection(
        id: 1,
        name: MailResourcesStrings.Localizable.settingsSectionEmailAddresses,
        items: getEmailAddresses()
    )
    static let general = SettingsSection(
        id: 2,
        name: MailResourcesStrings.Localizable.settingsSectionGeneral,
        items: [.send, .lock]
    )
    static let appearance = SettingsSection(
        id: 3,
        name: MailResourcesStrings.Localizable.settingsSectionAppearance,
        items: [.threadDensity, .theme, .accentColor, .swipeActions, .displayMode, .externalContent]
    )
}

private extension SettingsItem {
    static let send = SettingsItem(
        id: 1,
        title: MailResourcesStrings.Localizable.settingsSendTitle,
        type: .subMenu(destination: .send)
    )
    static let lock = SettingsItem(
        id: 2,
        title: MailResourcesStrings.Localizable.settingsAppLock,
        type: .toggle(userDefaults: \.isAppLockEnabled)
    )
    static let threadDensity = SettingsItem(
        id: 3,
        title: MailResourcesStrings.Localizable.settingsThreadListDensityTitle,
        type: .option(.threadDensityOption)
    )
    static let theme = SettingsItem(
        id: 4,
        title: MailResourcesStrings.Localizable.settingsTheme,
        type: .option(.themeOption)
    )
    static let accentColor = SettingsItem(
        id: 8,
        title: MailResourcesStrings.Localizable.settingsAccentColor,
        type: .option(.accentColor)
    )
    static let swipeActions = SettingsItem(
        id: 5,
        title: MailResourcesStrings.Localizable.settingsSwipeActionsTitle,
        type: .subMenu(destination: .swipe)
    )
    static let displayMode = SettingsItem(
        id: 6,
        title: MailResourcesStrings.Localizable.settingsMessageDisplayTitle,
        type: .option(.displayModeOption)
    )
    static let externalContent = SettingsItem(
        id: 7,
        title: MailResourcesStrings.Localizable.settingsExternalContentTitle,
        type: .option(.externalContentOption)
    )
}
