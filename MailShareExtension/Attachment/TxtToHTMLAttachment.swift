/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import MailCore

/// A wrapping type that can read an NSItemProvider that renders as a`.txt` on the fly and provide the content thanks to the
/// `TextAttachable` protocol
struct TxtToTextAttachment: HTMLAttachable {
    let item: NSItemProvider

    init?(wrapping item: NSItemProvider) {
        guard item.underlyingType == .isText else {
            return nil
        }

        self.item = item
    }

    // MARK: TextAttachable protocol

    var textAttachment: MailCore.TextAttachment {
        get async {
            guard let textAttachment = try? await item.writeToTemporaryURL() else {
                return (nil, nil)
            }

            guard let textData = NSData(contentsOf: textAttachment.url) else {
                return (nil, nil)
            }

            let textString = String(decoding: textData, as: UTF8.self)

            /// The `txt` file name is generated, so not useful for an email subject, discarding it
            return TextAttachment(title: nil, body: textString)
        }
    }

    // MARK: HTMLAttachable protocol

    var renderedHTML: String? {
        get async {
            guard let textString = await textAttachment.body else {
                return nil
            }

            /// Minimalist HTML sanitisation and support, non HTML text will work too.
            guard let document = try? SwiftSoupUtils(fromHTMLFragment: textString),
                  let cleanDocument = try? await document.cleanBody(),
                  let cleanHTML = try? cleanDocument.outerHtml() else {
                return nil
            }

            let finalHTML = "<div>" + cleanHTML + "</div>"
            return finalHTML
        }
    }
}
