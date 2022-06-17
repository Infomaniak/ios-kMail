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

@MainActor class SendSettingsViewModel: SettingsViewModel {
    init() {
        super.init(title: MailResourcesStrings.settingsSendTitle)
        sections = [.sendPage]
    }

    override func updateSelectedValue() {
        selectedValues = [
            .cancelDelayOption: UserDefaults.shared.cancelSendDelay,
            .forwardMessageOption: UserDefaults.shared.forwardMode
        ]
    }
}

private extension SettingsSection {
    static let sendPage = SettingsSection(
        id: 1,
        name: nil,
        items: [.cancelDelay, .forwardMessage, .includeOriginalInReply, .acknowledgement]
    )
}

private extension SettingsItem {
    static let cancelDelay = SettingsItem(
        id: 1,
        title: MailResourcesStrings.settingsCancellationPeriodTitle,
        type: .option(.cancelDelayOption)
    )
    static let forwardMessage = SettingsItem(
        id: 2,
        title: MailResourcesStrings.settingsTransferEmailsTitle,
        type: .option(.forwardMessageOption)
    )
    static let includeOriginalInReply = SettingsItem(
        id: 3,
        title: MailResourcesStrings.settingsSendIncludeOriginalMessage,
        type: .toggle(userDefaults: \.includeOriginalInReply)
    )
    static let acknowledgement = SettingsItem(
        id: 4,
        title: MailResourcesStrings.settingsSendAcknowledgement,
        type: .toggle(userDefaults: \.acknowledgement)
    )
}
