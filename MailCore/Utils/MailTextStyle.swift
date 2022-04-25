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

    public static let header = MailTextStyle(
        font: .system(size: 18, weight: .semibold),
        color: MailResourcesAsset.primaryTextColor
    )
    public static let primary = MailTextStyle(
        font: .system(size: 16, weight: .regular),
        color: MailResourcesAsset.primaryTextColor
    )
    public static let primaryHighlighted = MailTextStyle(
        font: .system(size: 16, weight: .semibold),
        color: MailResourcesAsset.primaryTextColor
    )
    public static let secondary = MailTextStyle(
        font: .system(size: 16, weight: .regular),
        color: MailResourcesAsset.secondaryTextColor
    )
    public static let highlighted = MailTextStyle(
        font: .system(size: 19, weight: .regular),
        color: MailResourcesAsset.primaryTextColor
    )
    public static let menuItem = MailTextStyle(
        font: .system(size: 16, weight: .regular),
        color: MailResourcesAsset.primaryTextColor
    )
    public static let menuItemSelected = MailTextStyle(
        font: .system(size: 16, weight: .semibold),
        color: InfomaniakCoreAsset.infomaniakColor
    )
    public static let menuTitle = MailTextStyle(
        font: .system(size: 15, weight: .regular),
        color: MailResourcesAsset.sectionHeaderTextColor
    )
    public static let badge = MailTextStyle(
        font: .system(size: 16, weight: .regular),
        color: InfomaniakCoreAsset.infomaniakColor
    )
    public static let smallAction = MailTextStyle(
        font: .system(size: 15, weight: .semibold),
        color: InfomaniakCoreAsset.infomaniakColor
    )
}
