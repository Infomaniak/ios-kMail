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

@MainActor class EmailAddressSettingsViewModel: SettingsViewModel {
    public var mailboxManager: MailboxManager
    @Published public var settings: MailboxSettings

    init(mailboxManager: MailboxManager) {
        self.mailboxManager = mailboxManager
        settings = mailboxManager.getSettings()

        super.init(title: mailboxManager.mailbox.email)

        sections = [.general /* , .inbox, .security, .privacy */ ]
    }

    override func updateSelectedValue() {
//        selectedValues = [
//
//        ]
    }
}

private extension SettingsSection {
    static let general = SettingsSection(
        id: 1,
        name: MailResourcesStrings.Localizable.settingsSectionGeneral,
        items: [.signature, .autoreply, .foldersSetting, .notifications]
    )
//    static let inbox = SettingsSection(
//        id: 2,
//        name: MailResourcesStrings.inboxFolder,
//        items: [.inboxType, .rules, .redirect, .alias]
//    )
//    static let security = SettingsSection(
//        id: 3,
//        name: MailResourcesStrings.settingsSectionSecurity,
//        items: [.adsFilter, .spamFilter, .blockedRecipient]
//    )
//    static let privacy = SettingsSection(
//        id: 4,
//        name: MailResourcesStrings.settingsSectionPrivacy,
//        items: [.deleteSearchHistory, .viewLogs]
//    )
}

private extension SettingsItem {
    static let signature = SettingsItem(
        id: 1,
        title: MailResourcesStrings.Localizable.settingsMailboxGeneralSignature,
        type: .option(.signatureOption)
    )
    static let autoreply = SettingsItem(
        id: 2,
        title: MailResourcesStrings.Localizable.settingsMailboxGeneralAutoreply,
        type: .option(.autoReplyOption)
    )
    static let foldersSetting = SettingsItem(
        id: 3,
        title: MailResourcesStrings.Localizable.settingsMailboxGeneralFolders,
        type: .option(.folderSettingsOption)
    )
    static let notifications = SettingsItem(
        id: 4,
        title: MailResourcesStrings.Localizable.settingsMailboxGeneralNotifications,
        type: .toggleBinding(keyPath: \.notifications)
    )

//    static let inboxType = SettingsItem(
//        id: 5,
//        title: MailResourcesStrings.settingsInboxType,
//        type: .option(<#T##SettingsOption#>)
//    )
//    static let rules = SettingsItem(
//        id: 6,
//        title: MailResourcesStrings.settingsInboxRules,
//        type: <#T##SettingsType#>
//    )
//    static let redirect = SettingsItem(
//        id: 7,
//        title: MailResourcesStrings.settingsInboxRedirect,
//        type: <#T##SettingsType#>
//    )
//    static let alias = SettingsItem(
//        id: 8,
//        title: MailResourcesStrings.settingsInboxAlias,
//        type: <#T##SettingsType#>
//    )
//
//    static let adsFilter = SettingsItem(
//        id: 9,
//        title: MailResourcesStrings.settingsSecurityAdsFilter,
//        type: <#T##SettingsType#>
//    )
//    static let spamFilter = SettingsItem(
//        id: 10,
//        title: MailResourcesStrings.settingsSecuritySpamFilter,
//        type: <#T##SettingsType#>
//    )
//    static let blockedRecipient = SettingsItem(
//        id: 11,
//        title: MailResourcesStrings.settingsSecurityBlockedRecipients,
//        type: <#T##SettingsType#>
//    )
//
//    static let deleteSearchHistory = SettingsItem(
//        id: 12,
//        title: MailResourcesStrings.settingsPrivacyDeleteSearchHistory,
//        type: <#T##SettingsType#>
//    )
//    static let viewLogs = SettingsItem(
//        id: 13,
//        title: MailResourcesStrings.settingsPrivacyViewLogs,
//        type: <#T##SettingsType#>
//    )
}
