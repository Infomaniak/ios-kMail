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
import InfomaniakCore
import InfomaniakDI

public extension FormatStyle where Self == Signature.FormatStyle {
    static func signature(style: Signature.FormatStyle.Style) -> Self {
        return .init(style: style)
    }
}

public extension Signature {
    func formatted(style: Signature.FormatStyle.Style) -> String {
        Self.FormatStyle(style: style).format(self)
    }

    struct FormatStyle: Foundation.FormatStyle {
        // Standard API does also nested types
        // swiftlint:disable:next nesting
        public enum Style: Codable {
            case long
            case short
            case option
        }

        private let style: Style

        public init(style: Style) {
            self.style = style
        }

        public func format(_ value: Signature) -> String {
            if style == .option {
                @LazyInjectService var platformDetector: PlatformDetectable
                if platformDetector.isMac {
                    return "\(value.senderName) (\(value.name)) \(value.senderEmailIdn)"
                } else {
                    return "\(value.senderName) (\(value.name))"
                }
            }
            if style == .short {
                return value.senderEmailIdn
            }
            return "\(value.senderName) <\(value.senderEmailIdn)> (\(value.name))"
        }
    }
}
