//
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

import AppIntents
import Foundation
import MailCore

extension Theme {
    var entity: ThemeEntity {
        switch self {
        case .dark:
            return .dark
        case .light:
            return .light
        case .system:
            return .system
        }
    }
}

enum ThemeEntity: String, AppEnum {
    case light
    case dark
    case system
    case appDefault

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        return TypeDisplayRepresentation(name: "settingsThemeTitle")
    }

    static var caseDisplayRepresentations: [ThemeEntity: DisplayRepresentation] = [
        .light: DisplayRepresentation(title: "settingsOptionLightTheme"),
        .dark: DisplayRepresentation(title: "settingsOptionDarkTheme"),
        .system: DisplayRepresentation(title: "settingsOptionSystemTheme"),
        .appDefault: DisplayRepresentation(title: "focusFilterAppDefaultTitle")
    ]

    var theme: Theme? {
        switch self {
        case .dark:
            return .dark
        case .light:
            return .light
        case .system:
            return .system
        case .appDefault:
            return nil
        }
    }
}
