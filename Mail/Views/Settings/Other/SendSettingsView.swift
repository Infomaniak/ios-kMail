/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

import InfomaniakCore
import InfomaniakCoreCommonUI
import MailResources
import SwiftUI

struct SendSettingsView: View {
    var body: some View {
        List {
            // Cancel period
            SettingsSubMenuCell(
                title: MailResourcesStrings.Localizable.settingsCancellationPeriodTitle,
                subtitle: UserDefaults.shared.threadDensity.title
            ) {
                SettingsOptionView(
                    title: MailResourcesStrings.Localizable.settingsCancellationPeriodTitle,
                    keyPath: \.cancelSendDelay,
                    matomoCategory: .settingsCancelPeriod,
                    matomoName: \.matomoName
                )
            }

            // Forward mode
            SettingsSubMenuCell(
                title: MailResourcesStrings.Localizable.settingsTransferEmailsTitle,
                subtitle: UserDefaults.shared.forwardMode.title
            ) {
                SettingsOptionView(
                    title: MailResourcesStrings.Localizable.settingsTransferEmailsTitle,
                    keyPath: \.forwardMode,
                    matomoCategory: .settingsForwardMode,
                    matomoName: \.rawValue
                )
            }

            // Include in reply
            SettingsToggleCell(
                title: MailResourcesStrings.Localizable.settingsSendIncludeOriginalMessage,
                userDefaults: \.includeOriginalInReply,
                matomoCategory: .settingsSend,
                matomoName: "includeOriginalInReply"
            )

            // Acknowledgement
            SettingsToggleCell(
                title: MailResourcesStrings.Localizable.settingsSendAcknowledgementTitle,
                userDefaults: \.acknowledgement,
                matomoCategory: .settingsSend,
                matomoName: "acknowledgement"
            )
        }
        .listStyle(.plain)
        .navigationBarTitle(MailResourcesStrings.Localizable.settingsSendTitle, displayMode: .inline)
        .backButtonDisplayMode(.minimal)
        .matomoView(view: [MatomoUtils.View.settingsView.displayName, "Send"])
    }
}

#Preview {
    SendSettingsView()
}
