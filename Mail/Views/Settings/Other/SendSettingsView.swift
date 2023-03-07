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
import MailResources
import SwiftUI

struct SendSettingsView: View {
    @State private var includeOriginal = false
    @State private var askAck = false

    var body: some View {
        List {
            // Cancel period
            SettingsSubMenuCell(
                title: MailResourcesStrings.Localizable.settingsCancellationPeriodTitle,
                subtitle: UserDefaults.shared.threadDensity.title
            ) {
                SettingsOptionView(
                    title: MailResourcesStrings.Localizable.settingsCancellationPeriodTitle,
                    keyPath: \.cancelSendDelay
                )
            }
            .settingCellModifier()

            // Forward mode
            SettingsSubMenuCell(
                title: MailResourcesStrings.Localizable.settingsTransferEmailsTitle,
                subtitle: UserDefaults.shared.forwardMode.title
            ) {
                SettingsOptionView(title: MailResourcesStrings.Localizable.settingsTransferEmailsTitle, keyPath: \.forwardMode)
            }
            .settingCellModifier()

            // Include in reply
            SettingsToggleCell(
                title: MailResourcesStrings.Localizable.settingsSendIncludeOriginalMessage,
                userDefaults: \.includeOriginalInReply
            )
            .settingCellModifier()

            // Acknowledgement
            SettingsToggleCell(
                title: MailResourcesStrings.Localizable.settingsSendAcknowledgement,
                userDefaults: \.acknowledgement
            )
            .settingCellModifier()
        }
        .listStyle(.plain)
        .navigationBarTitle(MailResourcesStrings.Localizable.settingsSendTitle, displayMode: .inline)
        .backButtonDisplayMode(.minimal)
        .matomoView(view: [MatomoUtils.View.settingsView.displayName, "Send"])
    }
}

struct SendSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SendSettingsView()
    }
}
