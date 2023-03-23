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

import InfomaniakCore
import InfomaniakCoreUI
import MailCore
import MailResources
import SwiftUI

struct SettingsView: View {
    @AppStorage(UserDefaults.shared.key(.threadDensity)) private var density = DefaultPreferences.threadDensity
    @AppStorage(UserDefaults.shared.key(.theme)) private var theme = DefaultPreferences.theme
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(MailResourcesStrings.Localizable.settingsSectionGeneral)
                    .textStyle(.bodySmallSecondary)

                SettingsToggleCell(
                    title: MailResourcesStrings.Localizable.settingsAppLock,
                    userDefaults: \.isAppLockEnabled,
                    matomoCategory: .settingsGeneral,
                    matomoName: "lock"
                )
                .settingCellModifier()

                SettingsSubMenuCell(title: MailResourcesStrings.Localizable.settingsMailboxGeneralNotifications) {
                    SettingsNotificationsView()
                }

                IKDivider()
            }
            .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 24) {
                Text(MailResourcesStrings.Localizable.settingsSectionAppearance)
                    .textStyle(.bodySmallSecondary)
                    .padding(.top, 16)

                // Thread density
                SettingsSubMenuCell(
                    title: MailResourcesStrings.Localizable.settingsThreadListDensityTitle,
                    subtitle: density.title
                ) {
                    SettingsThreadDensityOptionView()
                }

                // Theme
                SettingsSubMenuCell(
                    title: MailResourcesStrings.Localizable.settingsTheme,
                    subtitle: theme.title
                ) {
                    SettingsOptionView<Theme>(
                        title: MailResourcesStrings.Localizable.settingsThemeChoiceTitle,
                        subtitle: MailResourcesStrings.Localizable.settingsTheme,
                        keyPath: \.theme,
                        matomoCategory: .settingsTheme,
                        matomoName: \.rawValue
                    )
                }

                // Accent color
                SettingsSubMenuCell(
                    title: MailResourcesStrings.Localizable.settingsAccentColor,
                    subtitle: accentColor.title
                ) {
                    SettingsOptionView(
                        title: MailResourcesStrings.Localizable.settingsAccentColor,
                        keyPath: \.accentColor,
                        matomoCategory: .settingsAccentColor,
                        matomoName: \.rawValue
                    )
                }

                // Swipe actions
                SettingsSubMenuCell(title: MailResourcesStrings.Localizable.settingsSwipeActionsTitle) {
                    SettingsSwipeActionsView()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
        }
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .navigationBarTitle(MailResourcesStrings.Localizable.settingsTitle, displayMode: .inline)
        .backButtonDisplayMode(.minimal)
        .matomoView(view: [MatomoUtils.View.settingsView.displayName, "General"])
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
