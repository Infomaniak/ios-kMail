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
        font: .system(size: 21.5, weight: .bold),
        color: MailResourcesAsset.primaryTextColor
    )

    public static let header2 = MailTextStyle(
        font: .system(size: 17.5, weight: .bold),
        color: MailResourcesAsset.primaryTextColor
    )

    public static let header2Error = MailTextStyle(
        font: .system(size: 17.5, weight: .bold),
        color: MailResourcesAsset.redActionColor
    )

    public static let header3 = MailTextStyle(
        font: .system(size: 17.5),
        color: MailResourcesAsset.primaryTextColor
    )

    public static let header3Secondary = MailTextStyle(
        font: .system(size: 17.5),
        color: MailResourcesAsset.secondaryTextColor
    )

    public static let header3Error = MailTextStyle(
        font: .system(size: 17.5),
        color: MailResourcesAsset.redActionColor
    )

    public static let header4 = MailTextStyle(
        font: .system(size: 15.5, weight: .bold),
        color: MailResourcesAsset.primaryTextColor
    )

    public static let header4Accent = MailTextStyle(
        font: .system(size: 15.5, weight: .bold),
        color: \.primary
    )

    public static let header4Error = MailTextStyle(
        font: .system(size: 15.5, weight: .bold),
        color: MailResourcesAsset.redActionColor
    )

    public static let header5 = MailTextStyle(
        font: .system(size: 15.5, weight: .medium),
        color: MailResourcesAsset.primaryTextColor
    )

    public static let header5Accent = MailTextStyle(
        font: .system(size: 15.5, weight: .medium),
        color: \.primary
    )

    public static let header5OnAccent = MailTextStyle(
        font: .system(size: 15.5, weight: .medium),
        color: .white
    )

    public static let header5Error = MailTextStyle(
        font: .system(size: 15.5, weight: .medium),
        color: MailResourcesAsset.redActionColor
    )

    public static let body = MailTextStyle(
        font: .system(size: 15.5),
        color: MailResourcesAsset.primaryTextColor
    )

    public static let bodySecondary = MailTextStyle(
        font: .system(size: 15.5),
        color: MailResourcesAsset.secondaryTextColor
    )

    public static let calloutStrongAccent = MailTextStyle(
        font: .system(size: 13.5, weight: .bold),
        color: \.primary
    )

    public static let calloutStrongOnAccent = MailTextStyle(
        font: .system(size: 13.5, weight: .bold),
        color: .white
    )

    public static let calloutStrong = MailTextStyle(
        font: .system(size: 13.5, weight: .bold),
        color: MailResourcesAsset.primaryTextColor
    )

    public static let calloutMediumAccent = MailTextStyle(
        font: .system(size: 13.5, weight: .medium),
        color: \.primary
    )

    public static let calloutAccent = MailTextStyle(
        font: .system(size: 13.5),
        color: \.primary
    )

    public static let callout = MailTextStyle(
        font: .system(size: 13.5),
        color: MailResourcesAsset.primaryTextColor
    )

    public static let calloutSecondary = MailTextStyle(
        font: .system(size: 13.5),
        color: MailResourcesAsset.secondaryTextColor
    )

    public static let calloutTertiary = MailTextStyle(
        font: .system(size: 14.5),
        color: MailResourcesAsset.sectionHeaderTextColor
    )

    public static let calloutQuaternary = MailTextStyle(
        font: .system(size: 13.5),
        color: MailResourcesAsset.hintTextColor
    )

    public static let calloutWarning = MailTextStyle(
        font: .system(size: 13.5),
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
