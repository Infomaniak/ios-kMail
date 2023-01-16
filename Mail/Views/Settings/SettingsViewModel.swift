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
    case option(SettingsOption)
}

// MARK: - SettingsDestination

enum SettingsDestination: String, Equatable {
    case emailSettings
    case send
    case swipe

    @MainActor @ViewBuilder
    func getDestination() -> some View {
        switch self {
        case .emailSettings:
            EmptyView()
        case .send:
            SettingsView(viewModel: SendSettingsViewModel())
        case .swipe:
            SettingsSwipeActionsView(viewModel: SwipeActionSettingsViewModel())
        }
    }
}

// MARK: - SettingsOption

enum SettingsOption: Equatable {
    // General settings
    case threadDensityOption
    case themeOption
    case accentColor
    case externalContentOption

    // Send settings
    case cancelDelayOption
    case forwardMessageOption

    // Swipe
    case swipeShortRightOption
    case swipeLongRightOption
    case swipeShortLeftOption
    case swipeLongLeftOption

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
        case .externalContentOption:
            SettingsOptionView<ExternalContent>(
                title: MailResourcesStrings.Localizable.settingsExternalContentTitle,
                subtitle: MailResourcesStrings.Localizable.settingsSelectDisplayModeDescription,
                keyPath: \.displayExternalContent
            )
        case .cancelDelayOption:
            SettingsOptionView<CancelDelay>(
                title: MailResourcesStrings.Localizable.settingsCancellationPeriodTitle,
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
