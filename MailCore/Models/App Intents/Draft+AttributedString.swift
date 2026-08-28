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

extension AttributedString {
    init?(body: Body?) {
        guard let body, let value = body.value else { return nil }
        switch body.type {
        case .textPlain:
            self = AttributedString(value)
        case .textHtml, nil:
            guard let htmlAttributedString = AttributedString(htmlString: value) else {
                return nil
            }

            self = htmlAttributedString
        }
    }

    init?(htmlString: String) {
        guard let document = try? SwiftSoupUtils(fromHTML: htmlString).syncCleanBody(),
              let body = document.body(),
              let sanitizedHTML = try? body.outerHtml() else {
            return nil
        }

        let data = Data(sanitizedHTML.utf8)

        guard let attributedString = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        ) else {
            return nil
        }

        self.init(attributedString)
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
