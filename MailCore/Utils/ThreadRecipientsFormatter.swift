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

import Foundation
import MailResources

public extension FormatStyle where Self == Thread.FormatStyle {
    static func recipientNameList(
        context: MailboxManager?,
        style: Thread.FormatStyle.Style
    ) -> Self {
        .init(mailboxManagerFormattingContext: context, style: style)
    }
}

public extension Thread {
    func formatted(context: MailboxManager?, style: Thread.FormatStyle.Style) -> String {
        Self.FormatStyle(mailboxManagerFormattingContext: context, style: style).format(self)
    }

    struct FormatStyle: Foundation.FormatStyle, Codable, Equatable, Hashable {
        // swiftlint:disable nesting
        // Standard API does also nests types
        public enum Style: Codable, Equatable, Hashable {
            case to
            case from
        }

        var style: Style

        private var currentEmail: String?

        public init(mailboxManagerFormattingContext: MailboxManager?, style: Style) {
            self.currentEmail = mailboxManagerFormattingContext?.mailbox.email
            self.style = style
        }

        private func formattedFrom(thread: Thread) -> String {
            var fromArray = [Recipient]()
            for recipient in thread.from {
                guard !fromArray.contains(where: { $0.email == recipient.email && $0.name == recipient.name }) else { continue }
                fromArray.append(recipient)
            }

            switch fromArray.count {
            case 0:
                return MailResourcesStrings.Localizable.unknownRecipientTitle
            case 1:
                return fromArray[0].formatted(currentEmail: currentEmail)
            default:
                let fromCount = min(fromArray.count, Constants.threadCellMaxRecipients)
                return fromArray[0 ..< fromCount]
                    .map { $0.formatted(currentEmail: currentEmail, style: .shortName) }
                    .joined(separator: ", ")
            }
        }

        private func formattedTo(thread: Thread) -> String {
            guard let to = thread.to.last else { return MailResourcesStrings.Localizable.unknownRecipientTitle }
            return to.formatted(currentEmail: currentEmail)
        }

        public func format(_ value: Thread) -> String {
            switch style {
            case .to:
                return formattedTo(thread: value)
            case .from:
                return formattedFrom(thread: value)
            }
        }
    }
}
