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

enum ThreadDensityEntity: String, AppEnum {
    case compact
    case normal
    case large

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        return TypeDisplayRepresentation(stringLiteral: "settingsThreadListDensityTitle")
    }

    static var caseDisplayRepresentations: [ThreadDensityEntity: DisplayRepresentation] = [
        .compact: DisplayRepresentation(title: "settingsDensityOptionCompact"),
        .normal: DisplayRepresentation(title: "settingsDensityOptionNormal"),
        .large: DisplayRepresentation(title: "settingsDensityOptionLarge")
    ]

    var threadDensity: ThreadDensity {
        switch self {
        case .compact:
            return .compact
        case .normal:
            return .normal
        case .large:
            return .large
        }
    }
}
