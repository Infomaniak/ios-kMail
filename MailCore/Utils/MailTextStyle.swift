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
            return UserDefaults.shared.accentColor[keyPath: colorKeyPath].swiftUIColor
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
        color: MailResourcesAsset.textPrimaryColor
    )

    public static let header2 = MailTextStyle(
        font: .system(size: 18, weight: .semibold),
        color: MailResourcesAsset.textPrimaryColor
    )

    public static let header2Error = MailTextStyle(
        font: .system(size: 18, weight: .semibold),
        color: MailResourcesAsset.redColor
    )

    public static let bodyMedium = MailTextStyle(
        font: .system(size: 16, weight: .medium),
        color: MailResourcesAsset.textPrimaryColor
    )

    public static let bodyMediumAccent = MailTextStyle(
        font: .system(size: 16, weight: .medium),
        color: .accentColor
    )

    public static let bodyMediumOnAccent = MailTextStyle(
        font: .system(size: 16, weight: .medium),
        color: UserDefaults.shared.accentColor.onAccent.swiftUIColor
    )

    public static let bodyMediumOnAI = MailTextStyle(
        font: .system(size: 16, weight: .medium),
        color: MailResourcesAsset.onAIColor
    )

    public static let bodyMediumOnDisabled = MailTextStyle(
        font: .system(size: 16, weight: .medium),
        color: MailResourcesAsset.backgroundSecondaryColor
    )

    public static let bodyMediumError = MailTextStyle(
        font: .system(size: 16, weight: .medium),
        color: MailResourcesAsset.redColor
    )

    public static let body = MailTextStyle(
        font: .system(size: 16),
        color: MailResourcesAsset.textPrimaryColor
    )

    public static let bodyAccent = MailTextStyle(
        font: .system(size: 16),
        color: .accentColor
    )

    public static let bodyAccentSecondary = MailTextStyle(
        font: .system(size: 16),
        color: UserDefaults.shared.accentColor.secondary
    )

    public static let bodySecondary = MailTextStyle(
        font: .system(size: 16),
        color: MailResourcesAsset.textSecondaryColor
    )

    public static let bodyError = MailTextStyle(
        font: .system(size: 16),
        color: MailResourcesAsset.redColor
    )

    public static let bodySmallMedium = MailTextStyle(
        font: .system(size: 14, weight: .medium),
        color: MailResourcesAsset.textPrimaryColor
    )

    public static let bodySmallMediumAccent = MailTextStyle(
        font: .system(size: 14, weight: .medium),
        color: .accentColor
    )

    public static let bodySmallMediumOnAccent = MailTextStyle(
        font: .system(size: 14, weight: .medium),
        color: UserDefaults.shared.accentColor.onAccent.swiftUIColor
    )

    public static let bodySmall = MailTextStyle(
        font: .system(size: 14),
        color: MailResourcesAsset.textPrimaryColor
    )

    public static let bodySmallAccent = MailTextStyle(
        font: .system(size: 14),
        color: .accentColor
    )

    public static let bodySmallSecondary = MailTextStyle(
        font: .system(size: 14),
        color: MailResourcesAsset.textSecondaryColor
    )

    public static let bodySmallTertiary = MailTextStyle(
        font: .system(size: 14),
        color: MailResourcesAsset.textTertiaryColor
    )

    public static let bodySmallWarning = MailTextStyle(
        font: .system(size: 14),
        color: MailResourcesAsset.orangeColor
    )

    public static let labelMediumAccent = MailTextStyle(
        font: .system(size: 12, weight: .medium),
        color: .accentColor
    )

    public static let labelMedium = MailTextStyle(
        font: .system(size: 12, weight: .medium),
        color: MailResourcesAsset.textPrimaryColor
    )

    public static let labelSecondary = MailTextStyle(
        font: .system(size: 12),
        color: MailResourcesAsset.textSecondaryColor
    )

    public static let labelError = MailTextStyle(
        font: .system(size: 12),
        color: MailResourcesAsset.redColor
    )
}
