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

import Foundation
import MailResources
import SwiftUI

public enum Theme: String, CaseIterable, SettingsOptionEnum {
    case light
    case dark
    case system

    public var interfaceStyle: UIUserInterfaceStyle {
        let styles: [Theme: UIUserInterfaceStyle] = [
            .light: .light,
            .dark: .dark,
            .system: .unspecified
        ]
        return styles[self] ?? .unspecified
    }

    public var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }

    public var title: String {
        switch self {
        case .light:
            return MailResourcesStrings.Localizable.settingsOptionLightTheme
        case .dark:
            return MailResourcesStrings.Localizable.settingsOptionDarkTheme
        case .system:
            return MailResourcesStrings.Localizable.settingsOptionSystemTheme
        }
    }

    public var image: Image? {
        switch self {
        case .light:
            return MailResourcesAsset.themeLight.swiftUIImage
        case .dark:
            return MailResourcesAsset.themeDark.swiftUIImage
        case .system:
            return MailResourcesAsset.themeTel.swiftUIImage
        }
    }

    public var hint: String? {
        return nil
    }
}
