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

    public init(font: Font, color: Color) {
        self.font = font
        self.color = color
    }

    public init(font: Font, color: MailResourcesColors) {
        self.init(font: font, color: Color(color.color))
    }

    public init(font: Font, color: InfomaniakCoreColor) {
        self.init(font: font, color: Color(color.color))
    }

    public static let header1 = MailTextStyle(
        font: .system(size: 22, weight: .semibold),
        color: MailResourcesAsset.primaryTextColor
    )

    public static let header2 = MailTextStyle(
        font: .system(size: 18, weight: .semibold),
        color: MailResourcesAsset.primaryTextColor
    )

    public static let header2Secondary = MailTextStyle(
        font: .system(size: 18),
        color: MailResourcesAsset.secondaryTextColor
    )

    public static let header3 = MailTextStyle(
        font: .system(size: 16, weight: .semibold),
        color: MailResourcesAsset.primaryTextColor
    )

    public static let body = MailTextStyle(
        font: .system(size: 16),
        color: MailResourcesAsset.primaryTextColor
    )

    public static let bodySecondary = MailTextStyle(
        font: .system(size: 16),
        color: MailResourcesAsset.secondaryTextColor
    )

    public static let button = MailTextStyle(
        font: .system(size: 16, weight: .semibold),
        color: UserDefaults.shared.accentColor.primary
    )

    public static let buttonPill = MailTextStyle(
        font: .system(size: 16, weight: .semibold),
        color: .white
    )

    public static let calloutStrong = MailTextStyle(
        font: .system(size: 14, weight: .semibold),
        color: MailResourcesAsset.primaryTextColor
    )

    public static let callout = MailTextStyle(
        font: .system(size: 14),
        color: MailResourcesAsset.primaryTextColor
    )

    public static let calloutSecondary = MailTextStyle(
        font: .system(size: 14),
        color: MailResourcesAsset.secondaryTextColor
    )

    public static let calloutHint = MailTextStyle(
        font: .system(size: 14),
        color: MailResourcesAsset.hintTextColor
    )

    public static let calloutHighlighted = MailTextStyle(
        font: .system(size: 14),
        color: UserDefaults.shared.accentColor.primary
    )

    public static let snackbarBody = MailTextStyle(
        font: .system(size: 14),
        color: Color(uiColor: UIColor(hex: "#F5F5F5")!) // FIXME: Add to colors
    )

    public static let snackbarButton = MailTextStyle(
        font: .system(size: 14),
        color: Color(uiColor: UIColor(hex: "#4CB7FF")!) // FIXME: Add to colors
    )
}
