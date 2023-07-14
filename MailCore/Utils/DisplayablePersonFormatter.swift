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

public extension FormatStyle where Self == DisplayablePerson.FormatStyle {
    static func displayablePerson(style: DisplayablePerson.FormatStyle.Style = .fullName) -> Self {
        .init(style: style)
    }
}

public extension DisplayablePerson {
    func formatted(style: DisplayablePerson.FormatStyle.Style = .fullName) -> String {
        Self.FormatStyle(style: style).format(self)
    }

    struct FormatStyle: Foundation.FormatStyle, Codable, Equatable, Hashable {
        // swiftlint:disable nesting
        // Standard API does also nested types
        public enum Style: Codable, Equatable, Hashable {
            case shortName
            case fullName
            case initials
        }

        private let style: Style

        public init(style: Style = Style.fullName) {
            self.style = style
        }

        private func formattedFullName(_ displayablePerson: DisplayablePerson) -> String {
            return displayablePerson.fullName
        }

        private func formattedShortName(_ displayablePerson: DisplayablePerson) -> String {
            let formattedFullName = formattedFullName(displayablePerson)
            if Constants.isEmailAddress(formattedFullName) {
                return displayablePerson.email.components(separatedBy: "@").first ?? displayablePerson.email
            }

            return nameComponents(displayablePerson).givenName.removePunctuation
        }

        public func nameComponents(_ displayablePerson: DisplayablePerson) -> (givenName: String, familyName: String?) {
            let name = formattedFullName(displayablePerson)

            let components = name.components(separatedBy: .whitespaces)
            let givenName = components[0]
            let familyName = components.count > 1 ? components[1] : nil
            return (givenName, familyName)
        }

        private func formattedInitials(_ displayablePerson: DisplayablePerson) -> String {
            let nameComponents = nameComponents(displayablePerson)
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

        public func format(_ value: DisplayablePerson) -> String {
            switch style {
            case .shortName:
                return formattedShortName(value)
            case .fullName:
                return formattedFullName(value)
            case .initials:
                return formattedInitials(value)
            }
        }
    }
}
