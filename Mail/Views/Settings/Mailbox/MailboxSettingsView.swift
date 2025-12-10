/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

import InfomaniakCoreCommonUI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct MailboxSettingsView: View {
    let mailboxManager: MailboxManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SettingsSectionTitleView(title: MailResourcesStrings.Localizable.settingsSectionGeneral)

                SettingsSubMenuCell(title: MailResourcesStrings.Localizable.settingsMailboxGeneralSignature) {
                    MailboxSignatureSettingsView(mailboxManager: mailboxManager)
                }

                SettingsToggleCell(
                    title: MailResourcesStrings.Localizable.settingsSendAcknowledgementTitle,
                    subtitle: MailResourcesStrings.Localizable.settingsSendAcknowledgementSubtitle,
                    userDefaults: \.acknowledgement,
                    matomoCategory: .settingsSend,
                    matomoName: "acknowledgement"
                )
            }
        }
        .background(MailResourcesAsset.backgroundColor.swiftUIColor)
        .navigationTitle(mailboxManager.mailbox.email)
        .navigationBarTitleDisplayMode(.inline)
        .backButtonDisplayMode(.minimal)
        .matomoView(view: [MatomoUtils.View.settingsView.displayName, "Mailbox"])
    }
}

#Preview {
    MailboxSettingsView(mailboxManager: PreviewHelper.sampleMailboxManager)
}
