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
import MailResources
import SwiftUI

public enum SettingsPage: CaseIterable {
    case principal
    case sendPage
    case mailAddress
    case swipeActions

    public var title: String {
        switch self {
        case .principal:
            return MailResourcesStrings.settingsTitle
        case .sendPage:
            return MailResourcesStrings.settingsSendTitle
        case .mailAddress:
            return ""
        case .swipeActions:
            return MailResourcesStrings.settingsSwipeActionsTitle
        }
    }
}

class SettingsViewModel: ObservableObject {
    public var page: SettingsPage

    init(page: SettingsPage = .principal) {
        self.page = page
    }

    public var tableContent: [ParameterSection] {
        switch page {
        case .principal:
            return [.mailAddresses, .general, .appearance]
        case .sendPage:
            return [.send]
        case .mailAddress:
            return [.mailAddressGeneral, .mailAddressInbox, .mailAddressSecurity, .mailAddressPrivacy]
        case .swipeActions:
            return [.swipeActions]
        }
    }

    public func updateToggleSettings(for row: ParameterRow, with value: Bool) {
        switch row {
        case .codeLock:
            UserDefaults.shared.isAppLockEnabled = value
        default:
            return
        }
    }
}

// MARK: - ParameterSection

public enum ParameterSection: CaseIterable, Identifiable {
    public var id: Self { self }

    // Principal
    case mailAddresses
    case general
    case appearance

    // MailAddresses
    case mailAddressGeneral
    case mailAddressInbox
    case mailAddressSecurity
    case mailAddressPrivacy

    // Send
    case send

    // SwipeActions
    case swipeActions

    var title: String {
        switch self {
        case .mailAddresses:
            return MailResourcesStrings.settingsSectionEmailAddresses
        case .general:
            return MailResourcesStrings.settingsSectionGeneral
        case .appearance:
            return MailResourcesStrings.settingsSectionAppearance
        case .mailAddressGeneral:
            return MailResourcesStrings.settingsSectionGeneral
        case .mailAddressInbox:
            return MailResourcesStrings.inboxFolder
        case .mailAddressSecurity:
            return MailResourcesStrings.settingsSectionSecurity
        case .mailAddressPrivacy:
            return MailResourcesStrings.settingsSectionPrivacy
        case .send:
            return ""
        case .swipeActions:
            return ""
        }
    }

    var content: [ParameterRow] {
        switch self {
        case .mailAddresses:
            return []
        case .general:
            return [.send, .codeLock]
        case .appearance:
            return [.threadDensity, .theme, .swipeActions, .messageDisplay, .externalContent]
        case .mailAddressGeneral:
            return [.signature, .autoReply, .folderSettings, .notifications]
        case .mailAddressInbox:
            return [.inboxType, .rules, .redirect, .alias]
        case .mailAddressSecurity:
            return [.adsFilter, .spamFilter, .blockedRecipient]
        case .mailAddressPrivacy:
            return [.deleteHistory, .logs]
        case .send:
            return [.cancelPeriod, .emailTransfer, .includeOriginal, .acknowledgement]
        case .swipeActions:
            return [.shortRight, .longRight, .shortLeft, .longLeft]
        }
    }
}

// MARK: - ParameterRow

public enum ParameterRow: CaseIterable, Identifiable {
    public var id: Self { self }

    // Principal
    case send
    case codeLock
    case threadDensity
    case theme
    case swipeActions
    case messageDisplay
    case externalContent

    // MailAddresses
    case signature
    case autoReply
    case folderSettings
    case notifications
    case inboxType
    case rules
    case redirect
    case alias
    case adsFilter
    case spamFilter
    case blockedRecipient
    case deleteHistory
    case logs

    // Send
    case cancelPeriod
    case emailTransfer
    case includeOriginal
    case acknowledgement

    // SwipeActions
    case shortRight
    case longRight
    case shortLeft
    case longLeft

    var title: String {
        switch self {
        case .send:
            return MailResourcesStrings.settingsSendTitle
        case .codeLock:
            return MailResourcesStrings.settingsCodeLock
        case .threadDensity:
            return MailResourcesStrings.settingsThreadListDensityTitle
        case .theme:
            return MailResourcesStrings.settingsTheme
        case .swipeActions:
            return MailResourcesStrings.settingsSwipeActionsTitle
        case .messageDisplay:
            return MailResourcesStrings.settingsMessageDisplayTitle
        case .externalContent:
            return MailResourcesStrings.settingsExternalContentTitle
        case .signature:
            return MailResourcesStrings.settingsMailboxGeneralSignature
        case .autoReply:
            return MailResourcesStrings.settingsMailboxGeneralAutoreply
        case .folderSettings:
            return MailResourcesStrings.settingsMailboxGeneralFolders
        case .notifications:
            return MailResourcesStrings.settingsMailboxGeneralNotifications
        case .inboxType:
            return MailResourcesStrings.settingsInboxType
        case .rules:
            return MailResourcesStrings.settingsInboxRules
        case .redirect:
            return MailResourcesStrings.settingsInboxRedirect
        case .alias:
            return MailResourcesStrings.settingsInboxAlias
        case .adsFilter:
            return MailResourcesStrings.settingsSecurityAdsFilter
        case .spamFilter:
            return MailResourcesStrings.settingsSecuritySpamFilter
        case .blockedRecipient:
            return MailResourcesStrings.settingsSecurityBlockedRecipients
        case .deleteHistory:
            return MailResourcesStrings.settingsPrivacyDeleteSearchHistory
        case .logs:
            return MailResourcesStrings.settingsPrivacyViewLogs
        case .cancelPeriod:
            return MailResourcesStrings.settingsCancellationPeriodTitle
        case .emailTransfer:
            return MailResourcesStrings.settingsTransferEmailsTitle
        case .includeOriginal:
            return MailResourcesStrings.settingsSendIncludeOriginalMessage
        case .acknowledgement:
            return MailResourcesStrings.settingsSendAcknowledgement
        case .shortRight:
            return MailResourcesStrings.settingsSwipeShortRight
        case .longRight:
            return MailResourcesStrings.settingsSwipeLongRight
        case .shortLeft:
            return MailResourcesStrings.settingsSwipeShortLeft
        case .longLeft:
            return MailResourcesStrings.settingsSwipeLongLeft
        }
    }

    // TODO: - Fix description value
     var description: String? {
        switch self {
        case .threadDensity:
            return UserDefaults.shared.threadDensity.title
        case .theme:
            return UserDefaults.shared.theme.title
        case .swipeActions:
            return "swipeActions"
        case .messageDisplay:
            return "messageDisplay"
        case .externalContent:
            return UserDefaults.shared.displayExternalContent
                ? MailResourcesStrings.settingsOptionAlways
                : MailResourcesStrings.settingsOptionAskMe
        case .autoReply:
            return "autoreply"
        case .inboxType:
            return "inboxType"
        case .adsFilter:
            return "adsFilter"
        case .spamFilter:
            return "spamFilter"
        case .blockedRecipient:
            return "blockedRecipient"
        case .cancelPeriod:
            return "cancelPeriod"
        case .emailTransfer:
            return "emailTransfer"
        case .shortRight:
            return "shortRight"
        case .longRight:
            return "longRight"
        case .shortLeft:
            return "shortLeft"
        case .longLeft:
            return "longLeft"
        default:
            return nil
        }
    }

    var hasToggle: Bool {
        switch self {
        case .codeLock, .notifications, .adsFilter, .spamFilter, .includeOriginal, .acknowledgement:
            return true
        default:
            return false
        }
    }

    var isOn: Bool {
        switch self {
        case .codeLock:
            return UserDefaults.shared.isAppLockEnabled
        case .notifications:
            return UserDefaults.shared.isNotificationEnabled
//        case .adsFilter:
//        case .spamFilter:
//        case .includeOriginal:
//        case .acknowledgement:
        default:
            return false
        }
    }

    @MainActor var destination: AnyView? {
        switch self {
        case .send:
            return AnyView(SettingsView(viewModel: SettingsViewModel(page: .sendPage)))
        case .threadDensity:
            return nil
        case .theme:
            return AnyView(SettingsSelectionView(viewModel: ThemeSettingViewModel()))
        case .swipeActions:
            return AnyView(SettingsView(viewModel: SettingsViewModel(page: .swipeActions)))
//        case .messageDisplay:
//            return AnyView(SettingsSelectionView(viewModel: SettingsSelectionViewModel(page: .messageDisplay)))
//        case .externalContent:
//            return AnyView(SettingsSelectionView(viewModel: SettingsSelectionViewModel(page: .externalContent)))
        case .signature:
            return nil
        case .autoReply:
            return nil
        case .folderSettings:
            return nil
        case .inboxType:
            return nil
        case .rules:
            return nil
        case .redirect:
            return nil
        case .alias:
            return nil
        case .blockedRecipient:
            return nil
        case .logs:
            return nil
//        case .cancelPeriod:
//            return AnyView(SettingsSelectionView(viewModel: SettingsSelectionViewModel(page: .cancelDelay)))
//        case .emailTransfer:
//            return AnyView(SettingsSelectionView(viewModel: SettingsSelectionViewModel(page: .mailTransfer)))
//        case .shortRight, .longRight, .shortLeft, .longLeft:
//            return AnyView(SettingsSelectionView(viewModel: SettingsSelectionViewModel(page: .swipe)))
        default:
            return nil
        }
    }
}
