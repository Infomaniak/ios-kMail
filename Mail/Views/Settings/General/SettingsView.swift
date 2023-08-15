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
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct SettingsView: View {
    @InjectService private var accountManager: AccountManager

    @EnvironmentObject private var mailboxManager: MailboxManager

    @LazyInjectService private var appLockHelper: AppLockHelper

    @AppStorage(UserDefaults.shared.key(.threadDensity)) private var density = DefaultPreferences.threadDensity
    @AppStorage(UserDefaults.shared.key(.theme)) private var theme = DefaultPreferences.theme
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor
    @AppStorage(UserDefaults.shared.key(.externalContent)) private var externalContent = DefaultPreferences.externalContent
    @AppStorage(UserDefaults.shared.key(.threadMode)) private var threadMode = DefaultPreferences.threadMode

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(MailResourcesStrings.Localizable.settingsSectionEmailAddresses)
                    .textStyle(.bodySmallSecondary)

                ForEachMailboxView(userId: mailboxManager.account.userId) { mailbox in
                    if let mailboxManager = accountManager.getMailboxManager(for: mailbox) {
                        SettingsSubMenuCell(title: mailbox.email) {
                            MailboxSettingsView(mailboxManager: mailboxManager)
                        }
                    }
                }

                IKDivider()
            }
            .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 24) {
                Text(MailResourcesStrings.Localizable.settingsSectionGeneral)
                    .textStyle(.bodySmallSecondary)

                if appLockHelper.isAvailable {
                    SettingsToggleCell(
                        title: MailResourcesStrings.Localizable.settingsAppLock,
                        userDefaults: \.isAppLockEnabled,
                        matomoCategory: .settingsGeneral,
                        matomoName: "lock"
                    )
                    .settingCellModifier()
                }

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

                // MARK: - Thread Density

                SettingsSubMenuCell(
                    title: MailResourcesStrings.Localizable.settingsThreadListDensityTitle,
                    subtitle: density.title
                ) {
                    SettingsThreadDensityOptionView()
                }

                // MARK: - Theme

                SettingsSubMenuCell(
                    title: MailResourcesStrings.Localizable.settingsThemeTitle,
                    subtitle: theme.title
                ) {
                    SettingsOptionView<Theme>(
                        title: MailResourcesStrings.Localizable.settingsThemeTitle,
                        subtitle: MailResourcesStrings.Localizable.settingsThemeDescription,
                        keyPath: \.theme,
                        matomoCategory: .settingsTheme,
                        matomoName: \.rawValue
                    )
                }

                // MARK: - Accent Color

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

                // MARK: - Swipe Actions

                SettingsSubMenuCell(title: MailResourcesStrings.Localizable.settingsSwipeActionsTitle) {
                    SettingsSwipeActionsView()
                }

                // MARK: - Thread Mode

                SettingsSubMenuCell(
                    title: MailResourcesStrings.Localizable.settingsThreadModeTitle,
                    subtitle: threadMode.title
                ) {
                    SettingsThreadModeView()
                }

                // MARK: - External Content

                SettingsSubMenuCell(
                    title: MailResourcesStrings.Localizable.settingsExternalContentTitle,
                    subtitle: externalContent.title
                ) {
                    SettingsOptionView(
                        title: MailResourcesStrings.Localizable.settingsExternalContentTitle,
                        subtitle: MailResourcesStrings.Localizable.settingsExternalContentTitle,
                        keyPath: \.displayExternalContent,
                        matomoCategory: .settingsDisplayExternalContent,
                        matomoName: \.rawValue
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
        }
        .onChange(of: threadMode) { _ in
            AccountManager.instance.updateConversationSettings()
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
