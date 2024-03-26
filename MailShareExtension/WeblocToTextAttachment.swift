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

// import InfomaniakCore
import MailCore

/// A wrapping type that can read an NSItemProvider that renders as a`.webloc` on the fly and provide the content thanks to the
/// `TextAttachable` protocol
struct WeblocToTextAttachment: TextAttachable {
    let item: NSItemProvider

    init?(wrapping item: NSItemProvider) {
        guard item.underlyingType == .isURL else {
            return nil
        }

        self.item = item
    }

    // MARK: TextAttachable protocol

    var textAttachment: MailCore.TextAttachment {
        get async {
            guard let webloc = try? await item.writeToTemporaryURL() else {
                return (nil, nil)
            }

            guard let weblocData = NSData(contentsOf: webloc.url) else {
                return (nil, nil)
            }

            guard let parsedWebloc = try? PropertyListSerialization.propertyList(from: weblocData as Data,
                                                                                 options: [],
                                                                                 format: nil) as? NSDictionary else {
                return (nil, nil)
            }

            let parsedURL = parsedWebloc["URL"] as? String

            /// The `webloc` title is not useful for an email subject, discarding it
            return TextAttachment(title: nil, body: parsedURL)
        }
    }
}
