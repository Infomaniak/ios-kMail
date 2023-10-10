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
    public var color: Color

    private init(font: Font, color: Color) {
        self.font = font
        self.color = color
    }

    private init(mailFont: MailTextStyle, color: Color) {
        font = mailFont.font
        self.color = color
    }

    private init(font: MailTextStyle, weight: Font.Weight) {
        self.font = font.font.weight(weight)
        color = font.color
    }

    public static let header1 = MailTextStyle(
        font: .system(size: UIFontMetrics.default.scaledValue(for: 22)).weight(.semibold),
        color: MailResourcesAsset.textPrimaryColor.swiftUIColor
    )

    public static let header2 = MailTextStyle(
        font: .system(size: UIFontMetrics.default.scaledValue(for: 18)).weight(.semibold),
        color: MailResourcesAsset.textPrimaryColor.swiftUIColor
    )

    public static let header2Error = MailTextStyle(
        mailFont: .header2,
        color: MailResourcesAsset.redColor.swiftUIColor
    )

    public static let body = MailTextStyle(
        font: .system(size: UIFontMetrics.default.scaledValue(for: 16)),
        color: MailResourcesAsset.textPrimaryColor.swiftUIColor
    )

    public static let bodyMedium = MailTextStyle(
        font: .body,
        weight: .medium
    )

    public static let bodyMediumTertiary = MailTextStyle(
        mailFont: .bodyMedium,
        color: MailResourcesAsset.textTertiaryColor.swiftUIColor
    )

    public static let bodyMediumAccent = MailTextStyle(
        mailFont: .bodyMedium,
        color: .accentColor
    )

    public static let bodyMediumOnAccent = MailTextStyle(
        mailFont: .bodyMedium,
        color: UserDefaults.shared.accentColor.onAccent.swiftUIColor
    )

    public static let bodyMediumOnAI = MailTextStyle(
        mailFont: .bodyMedium,
        color: MailResourcesAsset.onAIColor.swiftUIColor
    )

    public static let bodyMediumOnDisabled = MailTextStyle(
        mailFont: .bodyMedium,
        color: MailResourcesAsset.backgroundSecondaryColor.swiftUIColor
    )

    public static let bodyMediumError = MailTextStyle(
        mailFont: .bodyMedium,
        color: MailResourcesAsset.redColor.swiftUIColor
    )

    public static let bodyAccent = MailTextStyle(
        mailFont: .body,
        color: .accentColor
    )

    public static let bodyAccentSecondary = MailTextStyle(
        mailFont: .body,
        color: UserDefaults.shared.accentColor.secondary.swiftUIColor
    )

    public static let bodySecondary = MailTextStyle(
        mailFont: .body,
        color: MailResourcesAsset.textSecondaryColor.swiftUIColor
    )

    public static let bodyError = MailTextStyle(
        mailFont: .body,
        color: MailResourcesAsset.redColor.swiftUIColor
    )

    public static let bodySmall = MailTextStyle(
        font: .system(size: UIFontMetrics.default.scaledValue(for: 14)),
        color: MailResourcesAsset.textPrimaryColor.swiftUIColor
    )

    public static let bodySmallMedium = MailTextStyle(
        font: .bodySmall,
        weight: .medium
    )

    public static let bodySmallMediumAccent = MailTextStyle(
        mailFont: .bodySmallMedium,
        color: .accentColor
    )

    public static let bodySmallMediumOnAccent = MailTextStyle(
        mailFont: .bodySmallMedium,
        color: UserDefaults.shared.accentColor.onAccent.swiftUIColor
    )

    public static let bodySmallAccent = MailTextStyle(
        mailFont: .bodySmall,
        color: .accentColor
    )

    public static let bodySmallSecondary = MailTextStyle(
        mailFont: .bodySmall,
        color: MailResourcesAsset.textSecondaryColor.swiftUIColor
    )

    public static let bodySmallItalicSecondary = MailTextStyle(
        font: .system(size: UIFontMetrics.default.scaledValue(for: 14)).italic(),
        color: MailResourcesAsset.textSecondaryColor.swiftUIColor
    )

    public static let bodySmallTertiary = MailTextStyle(
        mailFont: .bodySmall,
        color: MailResourcesAsset.textTertiaryColor.swiftUIColor
    )

    public static let bodySmallWarning = MailTextStyle(
        mailFont: .bodySmall,
        color: MailResourcesAsset.orangeColor.swiftUIColor
    )

    public static let label = MailTextStyle(
        font: .system(size: UIFontMetrics.default.scaledValue(for: 12)),
        color: MailResourcesAsset.textPrimaryColor.swiftUIColor
    )

    public static let labelMediumAccent = MailTextStyle(
        mailFont: .labelMedium,
        color: .accentColor
    )

    public static let labelMedium = MailTextStyle(
        font: .label,
        weight: .medium
    )

    public static let labelSecondary = MailTextStyle(
        mailFont: .label,
        color: MailResourcesAsset.textSecondaryColor.swiftUIColor
    )

    public static let labelError = MailTextStyle(
        mailFont: .label,
        color: MailResourcesAsset.redColor.swiftUIColor
    )
}
