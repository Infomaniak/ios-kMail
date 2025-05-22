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
import InfomaniakCore

public extension FormatStyle where Self == CommonContact.FormatStyle {
    static func displayablePerson(style: CommonContact.FormatStyle.Style = .fullName) -> Self {
        .init(style: style)
    }
}

public extension CommonContact {
    func formatted(style: CommonContact.FormatStyle.Style = .fullName) -> String {
        Self.FormatStyle(style: style).format(self)
    }

    struct FormatStyle: Foundation.FormatStyle, Codable, Equatable, Hashable {
        // Standard API does also nested types
        // swiftlint:disable:next nesting
        public enum Style: Codable, Equatable, Hashable {
            case shortName
            case fullName
            case initials
        }

        private let style: Style

        public init(style: Style = Style.fullName) {
            self.style = style
        }

        public func format(_ value: CommonContact) -> String {
            let nameFormatter = NameFormatter(fullName: value.fullName)
            switch style {
            case .shortName:
                return nameFormatter.shortName
            case .fullName:
                return nameFormatter.fullName
            case .initials:
                return nameFormatter.initials
            }
        }
    }
}
