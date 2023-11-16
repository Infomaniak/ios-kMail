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

import SwiftSoup

public enum SwiftSoupUtils {
    public static func extractHTML(from document: Document, _ cssQuery: String) throws -> String {
        guard let foundElement = try document.select(cssQuery).first() else {
            throw SwiftSoupError.elementNotFound
        }
        let htmlContent = try foundElement.outerHtml()
        return htmlContent
    }

    public static func extractText(from html: String) async throws -> String? {
        let document = try await SwiftSoup.parse(html)
        return try document.body()?.text()
    }
}

public extension SwiftSoupUtils {
    enum SwiftSoupError: Error {
        case elementNotFound
    }
}
