/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

import InfomaniakCore
import MailResources
import SwiftUI

public struct MailTextStyle {
    public let font: Font
    public let color: Color

    private init(font: Font, color: Color) {
        self.font = font
        self.color = color
    }

    private init(mailFont: MailTextStyle, color: Color) {
        self.init(font: mailFont.font, color: color)
    }

    private init(mailFont: MailTextStyle, weight: Font.Weight) {
        self.init(font: mailFont.font.weight(weight), color: mailFont.color)
    }
}

public extension MailTextStyle {
    // MARK: Header

    static let header1 = MailTextStyle(
        font: .system(size: UIFontMetrics.default.scaledValue(for: 22)).weight(.semibold),
        color: MailResourcesAsset.textPrimaryColor.swiftUIColor
    )

    static let header2 = MailTextStyle(
        font: .system(size: UIFontMetrics.default.scaledValue(for: 18)).weight(.semibold),
        color: MailResourcesAsset.textPrimaryColor.swiftUIColor
    )

    static let header2Error = MailTextStyle(
        mailFont: .header2,
        color: MailResourcesAsset.redColor.swiftUIColor
    )

    // MARK: Body

    static let body = MailTextStyle(
        font: .system(size: UIFontMetrics.default.scaledValue(for: 16)),
        color: MailResourcesAsset.textPrimaryColor.swiftUIColor
    )

    static let bodyWarning = MailTextStyle(
        mailFont: .body,
        color: MailResourcesAsset.orangeColor.swiftUIColor
    )

    static let bodyMedium = MailTextStyle(
        mailFont: .body,
        weight: .medium
    )

    static let bodyMediumSecondary = MailTextStyle(
        mailFont: .bodyMedium,
        color: MailResourcesAsset.textSecondaryColor.swiftUIColor
    )

    static let bodyMediumTertiary = MailTextStyle(
        mailFont: .bodyMedium,
        color: MailResourcesAsset.textTertiaryColor.swiftUIColor
    )

    static let bodyMediumAccent = MailTextStyle(
        mailFont: .bodyMedium,
        color: .accentColor
    )

    static let bodyMediumOnAccent = MailTextStyle(
        mailFont: .bodyMedium,
        color: UserDefaults.shared.accentColor.onAccent.swiftUIColor
    )

    static let bodyMediumOnDisabled = MailTextStyle(
        mailFont: .bodyMedium,
        color: MailResourcesAsset.backgroundSecondaryColor.swiftUIColor
    )

    static let bodyMediumError = MailTextStyle(
        mailFont: .bodyMedium,
        color: MailResourcesAsset.redColor.swiftUIColor
    )

    static let bodyAccent = MailTextStyle(
        mailFont: .body,
        color: .accentColor
    )

    static let bodyAccentSecondary = MailTextStyle(
        mailFont: .body,
        color: UserDefaults.shared.accentColor.secondary.swiftUIColor
    )

    static let bodySecondary = MailTextStyle(
        mailFont: .body,
        color: MailResourcesAsset.textSecondaryColor.swiftUIColor
    )

    static let bodyError = MailTextStyle(
        mailFont: .body,
        color: MailResourcesAsset.redColor.swiftUIColor
    )

    // MARK: BodySmall

    static let bodySmall = MailTextStyle(
        font: .system(size: UIFontMetrics.default.scaledValue(for: 14)),
        color: MailResourcesAsset.textPrimaryColor.swiftUIColor
    )

    static let bodySmallMedium = MailTextStyle(
        mailFont: .bodySmall,
        weight: .medium
    )

    static let bodySmallMediumAccent = MailTextStyle(
        mailFont: .bodySmallMedium,
        color: .accentColor
    )

    static let bodySmallMediumOnAccent = MailTextStyle(
        mailFont: .bodySmallMedium,
        color: UserDefaults.shared.accentColor.onAccent.swiftUIColor
    )

    static let bodySmallAccent = MailTextStyle(
        mailFont: .bodySmall,
        color: .accentColor
    )

    static let bodySmallSecondary = MailTextStyle(
        mailFont: .bodySmall,
        color: MailResourcesAsset.textSecondaryColor.swiftUIColor
    )

    static let bodySmallItalicSecondary = MailTextStyle(
        font: .system(size: UIFontMetrics.default.scaledValue(for: 14)).italic(),
        color: MailResourcesAsset.textSecondaryColor.swiftUIColor
    )

    static let bodySmallTertiary = MailTextStyle(
        mailFont: .bodySmall,
        color: MailResourcesAsset.textTertiaryColor.swiftUIColor
    )

    static let bodySmallWarning = MailTextStyle(
        mailFont: .bodySmall,
        color: MailResourcesAsset.orangeColor.swiftUIColor
    )

    // MARK: Label

    static let label = MailTextStyle(
        font: .system(size: UIFontMetrics.default.scaledValue(for: 12)),
        color: MailResourcesAsset.textPrimaryColor.swiftUIColor
    )

    static let labelMediumAccent = MailTextStyle(
        mailFont: .labelMedium,
        color: .accentColor
    )

    static let labelMedium = MailTextStyle(
        mailFont: .label,
        weight: .medium
    )

    static let labelSecondary = MailTextStyle(
        mailFont: .label,
        color: MailResourcesAsset.textSecondaryColor.swiftUIColor
    )

    static let labelError = MailTextStyle(
        mailFont: .label,
        color: MailResourcesAsset.redColor.swiftUIColor
    )

    static let labelDraggableThread = MailTextStyle(
        font: .system(size: UIFontMetrics.default.scaledValue(for: 36)),
        color: .accentColor
    )
}
