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

// MARK: - SettingsSection

struct SettingsSection: Identifiable, Equatable {
    var id: Int
    var name: String?
    var items: [SettingsItem]
}

// MARK: - SettingsItem

struct SettingsItem: Identifiable, Equatable {
    var id: Int
    var title: String
    var type: SettingsType
}

// MARK: - SettingsType

enum SettingsType: Equatable {
    case subMenu(destination: SettingsDestination)
    case toggle(userDefaults: ReferenceWritableKeyPath<UserDefaults, Bool>)
    case toggleBinding(keyPath: ReferenceWritableKeyPath<MailboxSettings, Bool>)
    case option(SettingsOption)
}

// MARK: - SettingsDestination

enum SettingsDestination: Equatable {
    case emailSettings(mailboxManager: MailboxManager)
    case send
    case swipe

    case signatureSettings(mailboxManager: MailboxManager)
    case blockedSettings(mailboxManager: MailboxManager)

    @MainActor @ViewBuilder
    func getDestination() -> some View {
        switch self {
        case let .emailSettings(mailboxManager):
            SettingsView(viewModel: EmailAddressSettingsViewModel(mailboxManager: mailboxManager))
        case .send:
            SettingsView(viewModel: SendSettingsViewModel())
        case .swipe:
            SettingsSwipeActionsView(viewModel: SwipeActionSettingsViewModel())
        case let .signatureSettings(mailboxManager):
            SettingsSignatureOptionView(mailboxManager: mailboxManager)
        case let .blockedSettings(mailboxManager):
            SettingsBlockedRecipientOptionView(mailboxManager: mailboxManager)
        }
    }

    static func == (lhs: SettingsDestination, rhs: SettingsDestination) -> Bool {
        switch (lhs, rhs) {
        case (.send, .send):
            return true
        case (.swipe, .swipe):
            return true
        case let (.emailSettings(lhsType), .emailSettings(rhsType)):
            return lhsType.mailbox == rhsType.mailbox
        case let (.signatureSettings(lhsType), .signatureSettings(rhsType)):
            return lhsType.mailbox == rhsType.mailbox
        case let (.blockedSettings(lhsType), .blockedSettings(rhsType)):
            return lhsType.mailbox == rhsType.mailbox
        default:
            return false
        }
    }
}

// MARK: - SettingsOption

enum SettingsOption: Equatable {
    // General settings
    case threadDensityOption
    case themeOption
    case accentColor
    case displayModeOption
    case externalContentOption

    // Send settings
    case cancelDelayOption
    case forwardMessageOption

    // Swipe
    case swipeShortRightOption
    case swipeLongRightOption
    case swipeShortLeftOption
    case swipeLongLeftOption

    // Email Address General
    case autoReplyOption
    case folderSettingsOption

    // Email Address Inbox
    case inboxTypeOption
//    case rulesOption
//    case redirectOption
//    case aliasOption
    
    // Email Address Security
//    case blockedRecipientOption

    @ViewBuilder
    func getDestination() -> some View {
        switch self {
        case .threadDensityOption:
            SettingsThreadDensityOptionView()
        case .themeOption:
            SettingsOptionView<Theme>(
                title: MailResourcesStrings.Localizable.settingsThemeChoiceTitle,
                subtitle: MailResourcesStrings.Localizable.settingsTheme,
                keyPath: \.theme
            )
        case .accentColor:
            SettingsOptionView<AccentColor>(
                title: MailResourcesStrings.Localizable.settingsAccentColor,
                subtitle: MailResourcesStrings.Localizable.settingsAccentColorDescription,
                keyPath: \.accentColor
            )
        case .displayModeOption:
            SettingsOptionView<ThreadMode>(
                title: MailResourcesStrings.Localizable.settingsMessageDisplayTitle,
                subtitle: MailResourcesStrings.Localizable.settingsSelectDisplayModeDescription,
                keyPath: \.threadMode
            )
        case .externalContentOption:
            SettingsOptionView<ExternalContent>(
                title: MailResourcesStrings.Localizable.settingsExternalContentTitle,
                subtitle: MailResourcesStrings.Localizable.settingsSelectDisplayModeDescription,
                keyPath: \.displayExternalContent
            )
        case .cancelDelayOption:
            SettingsOptionView<CancelDelay>(
                title: MailResourcesStrings.Localizable.settingsCancellationPeriodTitle,
                subtitle: MailResourcesStrings.Localizable.settingsCancellationPeriodDescription,
                keyPath: \.cancelSendDelay
            )
        case .forwardMessageOption:
            SettingsOptionView<ForwardMode>(
                title: MailResourcesStrings.Localizable.settingsTransferEmailsTitle,
                keyPath: \.forwardMode
            )
        case .swipeShortRightOption:
            SettingsOptionView<SwipeAction>(
                title: MailResourcesStrings.Localizable.settingsSwipeShortRight,
                keyPath: \.swipeShortRight,
                excludedKeyPath: [\.swipeLongRight, \.swipeShortLeft, \.swipeLongLeft]
            )
        case .swipeLongRightOption:
            SettingsOptionView<SwipeAction>(
                title: MailResourcesStrings.Localizable.settingsSwipeLongRight,
                keyPath: \.swipeLongRight,
                excludedKeyPath: [\.swipeShortRight, \.swipeShortLeft, \.swipeLongLeft]
            )
        case .swipeShortLeftOption:
            SettingsOptionView<SwipeAction>(
                title: MailResourcesStrings.Localizable.settingsSwipeShortLeft,
                keyPath: \.swipeShortLeft,
                excludedKeyPath: [\.swipeShortRight, \.swipeLongRight, \.swipeLongLeft]
            )
        case .swipeLongLeftOption:
            SettingsOptionView<SwipeAction>(
                title: MailResourcesStrings.Localizable.settingsSwipeLongLeft,
                keyPath: \.swipeLongLeft,
                excludedKeyPath: [\.swipeShortRight, \.swipeLongRight, \.swipeShortLeft]
            )
        case .autoReplyOption:
            EmptyView()
        case .folderSettingsOption:
            EmptyView()
        case .inboxTypeOption:
            EmptyView()
//        case .blockedRecipientOption:
//            SettingsBlockedRecipientOptionView()
        }
    }
}

@MainActor class SettingsViewModel: ObservableObject {
    public var title: String
    @Published public var selectedValues: [SettingsOption: SettingsOptionEnum] = [:]
    public var sections: [SettingsSection] = []

    init(title: String) {
        self.title = title
        updateSelectedValue()
    }

    func updateSelectedValue() {
        // Empty on purpose
    }
}
