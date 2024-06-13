/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

public extension FormatStyle where Self == Thread.FormatStyle {
    static func recipientNameList(
        contextMailboxManager: MailboxManager,
        style: Thread.FormatStyle.Style
    ) -> Self {
        .init(contextMailboxManager: contextMailboxManager, style: style)
    }
}

public extension Thread {
    func formatted(contextMailboxManager: MailboxManager, style: Thread.FormatStyle.Style) -> String {
        Self.FormatStyle(contextMailboxManager: contextMailboxManager, style: style).format(self)
    }

    struct FormatStyle: Foundation.FormatStyle, Codable, Equatable, Hashable {
        // Standard API does also nested types
        // swiftlint:disable:next nesting
        public enum Style: Codable, Equatable, Hashable {
            case to
            case from
        }

        private let style: Style
        private let contextMailboxManager: MailboxManager

        public init(contextMailboxManager: MailboxManager, style: Style) {
            self.style = style
            self.contextMailboxManager = contextMailboxManager
        }

        private func formattedFrom(thread: Thread) -> String {
            var fromArray = [Recipient]()
            for recipient in thread.from {
                guard !fromArray.contains(where: {
                    $0.email == recipient.email &&
                        ($0.name == recipient.name || $0.email == contextMailboxManager.mailbox.email)
                }) else { continue }
                fromArray.append(recipient)
            }

            switch fromArray.count {
            case 0:
                return MailResourcesStrings.Localizable.unknownRecipientTitle
            case 1:
                let contactConfiguration = ContactConfiguration.correspondent(
                    correspondent: fromArray[0],
                    contextMailboxManager: contextMailboxManager
                )
                let contact = CommonContactCache.getOrCreateContact(contactConfiguration: contactConfiguration)
                return contact.formatted()
            default:
                let fromCount = min(fromArray.count, Constants.threadCellMaxRecipients)
                return fromArray[0 ..< fromCount]
                    .map {
                        let contactConfiguration = ContactConfiguration.correspondent(
                            correspondent: $0,
                            contextMailboxManager: contextMailboxManager
                        )
                        let contact = CommonContactCache.getOrCreateContact(contactConfiguration: contactConfiguration)
                        return contact.formatted(style: .shortName)
                    }
                    .joined(separator: ", ")
            }
        }

        private func formattedTo(thread: Thread) -> String {
            guard let to = thread.to.first else { return MailResourcesStrings.Localizable.unknownRecipientTitle }
            let contact = CommonContactCache.getOrCreateContact(contactConfiguration: .correspondent(
                correspondent: to,
                contextMailboxManager: contextMailboxManager
            ))
            return contact.formatted()
        }

        public func format(_ value: Thread) -> String {
            switch style {
            case .to:
                return formattedTo(thread: value)
            case .from:
                return formattedFrom(thread: value)
            }
        }

        // MARK: Codable

        public init(from decoder: Decoder) throws {
            fatalError("Thread.FormatStyle init from Decoder is not supported")
        }

        public func encode(to encoder: Encoder) throws {
            fatalError("Thread.FormatStyle encode is not supported")
        }

        // MARK: Hashable

        public func hash(into hasher: inout Hasher) {
            hasher.combine(style)
            hasher.combine(contextMailboxManager.mailbox.objectId)
        }
    }
}
