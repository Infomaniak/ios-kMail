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

struct SettingsListView: View {
    @State private var lockEnable = false

    @AppStorage(UserDefaults.shared.key(.threadDensity), store: .shared) private var density = DefaultPreferences.threadDensity
    @AppStorage(UserDefaults.shared.key(.theme), store: .shared) private var theme = DefaultPreferences.theme
    @AppStorage(UserDefaults.shared.key(.accentColor), store: .shared) private var accentColor = DefaultPreferences.accentColor

    var body: some View {
        List {
            // TODO: - Mail address settings

            Section {
                SettingsSectionHeaderView(title: MailResourcesStrings.Localizable.settingsSectionGeneral, separator: true)
                    .settingSectionHeaderModifier()

                // TODO: - Send settings

                // TODO: - Programmation settings

                SettingsToggleCell(title: MailResourcesStrings.Localizable.settingsAppLock, userDefaults: \.isAppLockEnabled)
                    .settingCellModifier()
            }
            .listSectionSeparator(.hidden)

            Section {
                SettingsSectionHeaderView(title: MailResourcesStrings.Localizable.settingsSectionAppearance, separator: true)
                    .settingSectionHeaderModifier()

                // Thread density
                SettingsSubMenuCell(
                    title: MailResourcesStrings.Localizable.settingsThreadListDensityTitle,
                    subtitle: density.title
                ) {
                    SettingsThreadDensityOptionView()
                }
                .settingCellModifier()

                // Theme
                SettingsSubMenuCell(
                    title: MailResourcesStrings.Localizable.settingsTheme,
                    subtitle: theme.title
                ) {
                    SettingsOptionView<Theme>(
                        title: MailResourcesStrings.Localizable.settingsThemeChoiceTitle,
                        subtitle: MailResourcesStrings.Localizable.settingsTheme,
                        keyPath: \.theme
                    )
                }
                .settingCellModifier()

                // Accent color
                SettingsSubMenuCell(
                    title: MailResourcesStrings.Localizable.settingsAccentColor,
                    subtitle: accentColor.title
                ) {
                    SettingsOptionView(
                        title: MailResourcesStrings.Localizable.settingsAccentColor,
                        keyPath: \.accentColor
                    )
                }
                .settingCellModifier()

                // Swipe actions
                SettingsSubMenuCell(title: MailResourcesStrings.Localizable.settingsSwipeActionsTitle) {
                    SettingsSwipeActionsView()
                }
                .settingCellModifier()

                // TODO: - Message conversation mode

                // TODO: - Display external content
            }
            .listSectionSeparator(.hidden)
        }
        .listStyle(.plain)
        .navigationBarTitle(MailResourcesStrings.Localizable.settingsTitle, displayMode: .inline)
        .backButtonDisplayMode(.minimal)
    }
}

struct SettingsListView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsListView()
    }
}
