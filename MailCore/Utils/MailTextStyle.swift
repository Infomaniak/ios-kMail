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

import InfomaniakCore
import MailResources
import SwiftUI

public struct MailTextStyle {
    public var font: Font
    private var colorType: Color

    public var color: SwiftUI.Color {
        switch colorType {
        case .staticColor(let color):
            return color
        case .accentColor(let colorKeyPath):
            return UserDefaults.shared.accentColor[keyPath: colorKeyPath].swiftUiColor
        }
    }

    private enum Color {
        case staticColor(SwiftUI.Color)
        case accentColor(KeyPath<AccentColor, MailResourcesColors>)
    }

    private init(font: Font, colorType: Color) {
        self.font = font
        self.colorType = colorType
    }

    public init(font: Font, color: SwiftUI.Color) {
        self.init(font: font, colorType: .staticColor(color))
    }

    public init(font: Font, color: MailResourcesColors) {
        self.init(font: font, color: .init(color.color))
    }

    public init(font: Font, color: KeyPath<AccentColor, MailResourcesColors>) {
        self.init(font: font, colorType: .accentColor(color))
    }

    public static let header1 = MailTextStyle(
        font: .system(size: 22, weight: .semibold),
        color: MailResourcesAsset.primaryTextColor
    )

    public static let header2 = MailTextStyle(
        font: .system(size: 18, weight: .semibold),
        color: MailResourcesAsset.primaryTextColor
    )

    public static let bodyMedium = MailTextStyle(
        font: .system(size: 16, weight: .medium),
        color: MailResourcesAsset.primaryTextColor
    )

    public static let bodyMediumAccent = MailTextStyle(
        font: .system(size: 16, weight: .medium),
        color: \.primary
    )

    public static let bodyMediumOnAccent = MailTextStyle(
        font: .system(size: 16, weight: .medium),
        color: MailResourcesAsset.onAccentColor
    )

    public static let bodyMediumError = MailTextStyle(
        font: .system(size: 16, weight: .medium),
        color: MailResourcesAsset.redActionColor
    )

    public static let body = MailTextStyle(
        font: .system(size: 16),
        color: MailResourcesAsset.primaryTextColor
    )

    public static let bodySecondary = MailTextStyle(
        font: .system(size: 16),
        color: MailResourcesAsset.secondaryTextColor
    )

    public static let bodyError = MailTextStyle(
        font: .system(size: 16),
        color: MailResourcesAsset.redActionColor
    )

    public static let bodySmallMedium = MailTextStyle(
        font: .system(size: 14, weight: .medium),
        color: MailResourcesAsset.primaryTextColor
    )

    public static let bodySmallMediumAccent = MailTextStyle(
        font: .system(size: 14, weight: .medium),
        color: \.primary
    )

    public static let bodySmallMediumOnAccent = MailTextStyle(
        font: .system(size: 14, weight: .medium),
        color: MailResourcesAsset.onAccentColor
    )

    public static let bodySmall = MailTextStyle(
        font: .system(size: 14),
        color: MailResourcesAsset.primaryTextColor
    )

    public static let bodySmallAccent = MailTextStyle(
        font: .system(size: 14),
        color: \.primary
    )

    public static let bodySmallSecondary = MailTextStyle(
        font: .system(size: 14),
        color: MailResourcesAsset.secondaryTextColor
    )

    public static let bodySmallTertiary = MailTextStyle(
        font: .system(size: 14),
        color: MailResourcesAsset.hintTextColor
    )

    public static let bodySmallWarning = MailTextStyle(
        font: .system(size: 14),
        color: MailResourcesAsset.warningColor
    )

    public static let captionMediumAccent = MailTextStyle(
        font: .system(size: 11.5, weight: .medium),
        color: \.primary
    )

    public static let captionMediumSecondary = MailTextStyle(
        font: .system(size: 11.5, weight: .medium),
        color: MailResourcesAsset.secondaryTextColor
    )

    public static let captionSecondary = MailTextStyle(
        font: .system(size: 11.5),
        color: MailResourcesAsset.secondaryTextColor
    )
}
