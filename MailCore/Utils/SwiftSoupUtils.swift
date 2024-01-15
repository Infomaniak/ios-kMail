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

public struct SwiftSoupUtils {
    private let document: Document

    public init(document: Document) {
        self.document = document
    }

    public init(fromHTML html: String) throws {
        document = try SwiftSoup.parse(html)
    }

    public init(fromHTMLFragment html: String) throws {
        document = try SwiftSoup.parseBodyFragment(html)
    }

    public func cleanBody() async throws -> Document {
        let cleanedDocument = try SwiftSoup.Cleaner(headWhitelist: nil, bodyWhitelist: .extendedBodyWhitelist).clean(document)
        return cleanedDocument
    }

    public func cleanCompleteDocument() async throws -> Document {
        let cleanedDocument = try SwiftSoup.Cleaner(headWhitelist: .headWhitelist, bodyWhitelist: .extendedBodyWhitelist)
            .clean(document)

        // We need to remove the tag <meta http-equiv="refresh" content="x">
        let metaRefreshTags = try await cleanedDocument.select("meta[http-equiv='refresh']")
        for metaRefreshTag in metaRefreshTags {
            try metaRefreshTag.parent()?.removeChild(metaRefreshTag)
        }

        return cleanedDocument
    }

    public func extractParentElement() async -> Element? {
        return document.body()?.children().first()
    }

    public func extractHTML(_ cssQuery: String) async throws -> String {
        guard let foundElement = try await document.select(cssQuery).first() else { throw SwiftSoupError.elementNotFound }

        let htmlContent = try foundElement.outerHtml()
        return htmlContent
    }

    public func extractText() async throws -> String? {
        return try document.body()?.text()
    }
}

public extension SwiftSoupUtils {
    enum SwiftSoupError: Error {
        case elementNotFound
    }
}
