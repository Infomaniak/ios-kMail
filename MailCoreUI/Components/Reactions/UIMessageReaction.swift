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
import MailCore

public struct UIMessageReaction: Identifiable, Equatable, Hashable {
    public var id: String { emoji }

    public let emoji: String
    public let authors: [UIReactionAuthor]
    public let hasUserReacted: Bool

    public init(reaction: String, authors: [UIReactionAuthor], hasUserReacted: Bool = false) {
        emoji = reaction
        self.authors = authors
        self.hasUserReacted = hasUserReacted
    }

    public init(messageReaction: MessageReaction) {
        self.init(
            reaction: messageReaction.reaction,
            authors: messageReaction.authors.compactMap { UIReactionAuthor(author: $0) },
            hasUserReacted: messageReaction.hasUserReacted
        )
    }
}

public struct UIReactionAuthor: Identifiable, Equatable, Hashable {
    public var id: String { recipient.id }

    public let recipient: Recipient
    public let bimi: Bimi?

    init(recipient: Recipient, bimi: Bimi?) {
        self.recipient = recipient
        self.bimi = bimi
    }

    init?(author: ReactionAuthor) {
        guard let recipient = author.recipient else { return nil }

        self.recipient = recipient
        bimi = author.bimi
    }
}

// MARK: - FormatStyle

public extension UIMessageReaction {
    struct ReactionFormatStyle: FormatStyle {
        public func format(_ value: UIMessageReaction) -> String {
            return "\(value.emoji) \(value.authors.count)"
        }
    }

    func formatted() -> String {
        let formatStyle = ReactionFormatStyle()
        return formatStyle.format(self)
    }
}

public extension FormatStyle where Self == UIMessageReaction.ReactionFormatStyle {
    static var reaction: Self {
        UIMessageReaction.ReactionFormatStyle()
    }
}
