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

public extension String {
    var removePunctuation: String {
        guard !contains("@") else { return self }
        let sanitizedString = components(separatedBy: CharacterSet.punctuationCharacters).joined(separator: "")
        return sanitizedString.isEmpty ? self : sanitizedString
    }

    var normalizedApostrophes: String {
        return replacingOccurrences(of: "'", with: "’")
    }

    var withNewLineIntoHTML: String {
        replacingOccurrences(of: "\n", with: "<br>")
    }

    func wrapInHTMLTag(_ tag: String) -> String {
        return "<\(tag)>\(self)</\(tag)>"
    }

    var trimmedAndWithoutNewlines: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: " ")
    }

    func removePrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }

    func removeSuffix(_ suffix: String) -> String {
        guard hasSuffix(suffix) else { return self }
        return String(dropLast(suffix.count))
    }

    func parseMessageIds() -> [String] {
        let string = removePrefix("<").removeSuffix(">")
        guard !string.isEmpty else { return [] }

        let modString = Constants.referenceRegex.stringByReplacingMatches(
            in: string,
            range: NSRange(location: 0, length: string.count),
            withTemplate: "><"
        )
        return modString.components(separatedBy: "><")
    }
}
