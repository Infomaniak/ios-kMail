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
import MailResources

public extension Message {
    func formatted<F: Foundation.FormatStyle>(_ style: F) -> F.FormatOutput where F.FormatInput == Message {
        style.format(self)
    }

    struct PreviewFormatStyle: Foundation.FormatStyle {
        public static let noPreview = MailResourcesStrings.Localizable.noBodyTitle
        public func format(_ value: Message) -> String {
            if value.encrypted {
                return MailResourcesStrings.Localizable.encryptedMessageHeader
            } else if value.isReaction {
                return getCleanEmojiPreviewFrom(message: value)
            } else if !value.preview.isEmpty {
                return value.preview
            }
            return Self.noPreview
        }

        private func getCleanEmojiPreviewFrom(message: Message) -> String {
            guard let emojiReaction = message.emojiReaction, let firstFrom = message.from.first else {
                return message.preview
            }

            let name: String
            if !firstFrom.name.isEmpty {
                name = firstFrom.name
            } else {
                name = firstFrom.email
            }

            let preview = MailResourcesStrings.Localizable.previewReaction(name, emojiReaction)
            return preview
        }
    }
}

public extension FormatStyle where Self == Message.PreviewFormatStyle {
    static var preview: Message.PreviewFormatStyle {
        return .init()
    }
}
