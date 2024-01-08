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

extension AccentColor {
    var entity: AccentColorEntity {
        switch self {
        case .pink:
            return .pink
        case .blue:
            return .blue
        }
    }
}

// Enum is duplicated from AccentColor because AppIntents needs to have the type inside the target to compile...
enum AccentColorEntity: String, AppEnum {
    case pink
    case blue

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        return TypeDisplayRepresentation(name: "settingsAccentColor")
    }

    static var caseDisplayRepresentations: [AccentColorEntity: DisplayRepresentation] = [
        .pink: DisplayRepresentation(title: "accentColorPinkTitle"),
        .blue: DisplayRepresentation(title: "accentColorBlueTitle")
    ]

    var accentColor: AccentColor {
        switch self {
        case .pink:
            return .pink
        case .blue:
            return .blue
        }
    }
}
