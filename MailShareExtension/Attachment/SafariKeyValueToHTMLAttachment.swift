/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import Foundation
import MailCore

struct SafariKeyValueToHTMLAttachment: HTMLAttachable {
    let item: TextAttachable

    init(wrapping item: TextAttachable) {
        self.item = item
    }

    // MARK: TextAttachable protocol

    var textAttachment: MailCore.TextAttachment {
        get async {
            await item.textAttachment
        }
    }

    // MARK: HTMLAttachable protocol

    var renderedHTML: String? {
        get async {
            guard let urlString = await textAttachment.body,
                  let bodyUrl = URL(string: urlString) else {
                return nil
            }

            let bodyAbsoluteUrl = bodyUrl.absoluteString
            guard !bodyAbsoluteUrl.isEmpty else {
                return nil
            }

            let finalHTML = "<div class=\"renderedHTML\"><a href=\"\(bodyAbsoluteUrl)\">" + bodyAbsoluteUrl + "</a></div>"
            return finalHTML
        }
    }
}
