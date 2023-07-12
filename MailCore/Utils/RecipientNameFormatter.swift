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

public extension FormatStyle where Self == Recipient.FormatStyle {
    static func recipient(context: MailboxManager?, style: Recipient.FormatStyle.Style = .fullName) -> Self {
        .init(mailboxManagerFormattingContext: context, style: style)
    }
}

public extension Recipient {
    func formatted(context: MailboxManager?, style: Recipient.FormatStyle.Style = .fullName) -> String {
        Self.FormatStyle(mailboxManagerFormattingContext: context, style: style).format(self)
    }

    func formatted(currentEmail: String?, style: Recipient.FormatStyle.Style = .fullName) -> String {
        Self.FormatStyle(currentEmail: currentEmail, style: style).format(self)
    }

    struct FormatStyle: Foundation.FormatStyle, Codable, Equatable, Hashable {
        // swiftlint:disable nesting
        // Standard API does also nests types
        public enum Style: Codable, Equatable, Hashable {
            case shortName
            case fullName
            case initials
        }

        public static func == (lhs: Recipient.FormatStyle, rhs: Recipient.FormatStyle) -> Bool {
            return lhs.style == rhs.style
                && lhs.currentEmail == rhs.currentEmail
                && lhs.contactManager?.realmConfiguration.fileURL == rhs.contactManager?.realmConfiguration.fileURL
        }

        var style: Style

        private var currentEmail: String?
        private var contactManager: ContactManager?

        public init(mailboxManagerFormattingContext: MailboxManager?, style: Style = Style.fullName) {
            currentEmail = mailboxManagerFormattingContext?.mailbox.email
            self.style = style
        }

        public init(currentEmail: String?, style: Style = Style.fullName) {
            self.currentEmail = currentEmail
            self.style = style
        }

        private func isMe(recipient: Recipient) -> Bool {
            guard let currentEmail else { return false }
            return recipient.isMe(currentMailboxEmail: currentEmail)
        }

        private func formattedFullName(recipient: Recipient) -> String {
            if isMe(recipient: recipient) {
                return MailResourcesStrings.Localizable.contactMe
            }
            let contact = contactManager?.getContact(for: recipient)
            return contact?.name ?? (recipient.name.isEmpty ? recipient.email : recipient.name)
        }

        private func formattedShortName(recipient: Recipient) -> String {
            let isMe = isMe(recipient: recipient)

            let formattedFullName = formattedFullName(recipient: recipient)
            if Constants.isEmailAddress(formattedFullName) {
                return recipient.email.components(separatedBy: "@").first ?? recipient.email
            }

            if isMe {
                return MailResourcesStrings.Localizable.contactMe
            }

            return nameComponents(recipient: recipient).givenName.removePunctuation
        }

        public func nameComponents(recipient: Recipient) -> (givenName: String, familyName: String?) {
            let name = formattedFullName(recipient: recipient)

            let components = name.components(separatedBy: .whitespaces)
            let givenName = components[0]
            let familyName = components.count > 1 ? components[1] : nil
            return (givenName, familyName)
        }

        private func formattedInitials(recipient: Recipient) -> String {
            let nameComponents = nameComponents(recipient: recipient)
            let initials = [nameComponents.givenName, nameComponents.familyName]
                .compactMap {
                    if let firstCharacter = $0?.removePunctuation.first {
                        return String(firstCharacter)
                    } else {
                        return nil
                    }
                }
            return initials.joined().uppercased()
        }

        public func format(_ value: Recipient) -> String {
            switch style {
            case .shortName:
                return formattedShortName(recipient: value)
            case .fullName:
                return formattedFullName(recipient: value)
            case .initials:
                return formattedInitials(recipient: value)
            }
        }

        public init(from decoder: Decoder) throws {
            fatalError("Recipient.FormatStyle init from Decoder is not supported")
        }

        public func encode(to encoder: Encoder) throws {
            fatalError("Encode is not supported")
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(style)
            hasher.combine(currentEmail)
            hasher.combine(contactManager?.realmConfiguration.fileURL)
        }
    }
}
