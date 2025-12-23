/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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

public struct SubjectFormatter: FormatStyle {
    public func format(_ value: String) -> String {
        let normalizedSubject = value.precomposedStringWithCompatibilityMapping

        let cleanedSubject = String(normalizedSubject.unicodeScalars.map { scalar -> Character in
            if scalar.isIllegalInSubject {
                return " "
            } else {
                return Character(scalar)
            }
        })

        return cleanedSubject
    }
}

public extension FormatStyle where Self == SubjectFormatter {
    static var cleanSubject: SubjectFormatter {
        return SubjectFormatter()
    }
}

extension UnicodeScalar {
    var isInvisible: Bool {
        properties.generalCategory == .format ||
            properties.generalCategory == .control
    }

    var isBidiControl: Bool {
        switch value {
        case 0x202A ... 0x202E, 0x2066 ... 0x2069:
            return true
        default:
            return false
        }
    }

    var isIllegalInSubject: Bool {
        if isInvisible || properties.isJoinControl || isBidiControl {
            return true
        }

        return false
    }
}
