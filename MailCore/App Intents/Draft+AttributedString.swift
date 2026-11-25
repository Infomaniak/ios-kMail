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
import SwiftSoup

extension AttributedString {
    static func bodyToIndexableAttributedString(body: Body?) -> AttributedString? {
        guard let body, let value = body.value else { return nil }
        switch body.type {
        case .textPlain:
            return AttributedString(value)
        case .textHtml, nil:
            return htmlBodyToIndexableAttributedString(htmlBody: value)
        }
    }

    static func htmlBodyToIndexableAttributedString(htmlBody: String) -> AttributedString? {
        // No cleaning needed: text() only collects text nodes, script and style contents are data nodes.
        guard let body = try? SwiftSoup.parse(htmlBody).body(),
              let bodyText = try? body.text() else {
            return nil
        }
        return AttributedString(bodyText)
    }

    var htmlString: String? {
        let nsAttributedString = NSAttributedString(self)

        guard let htmlData = try? nsAttributedString.data(
            from: NSRange(location: 0, length: nsAttributedString.length),
            documentAttributes: [
                .documentType: NSAttributedString.DocumentType.html
            ]
        )
        else {
            return nil
        }

        return String(data: htmlData, encoding: .utf8)
    }
}
