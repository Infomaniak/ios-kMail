//
/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import InfomaniakCoreUI
import MailCore
import MailResources
import SwiftUI

public extension IKButtonTheme {
    static let mail = IKButtonTheme(
        primary: TintShapeStyle.tint,
        secondary: UserDefaults.shared.accentColor.onAccent.swiftUIColor,
        disabledPrimary: MailResourcesAsset.textTertiaryColor.swiftUIColor,
        disabledSecondary: MailTextStyle.bodyMediumOnDisabled.color,
        error: MailResourcesAsset.redColor.swiftUIColor,
        smallFont: MailTextStyle.bodySmall.font,
        mediumFont: MailTextStyle.bodyMedium.font
    )

    static let aiWriter = IKButtonTheme(
        primary: MailResourcesAsset.aiColor.swiftUIColor,
        secondary: MailResourcesAsset.backgroundSecondaryColor.swiftUIColor,
        disabledPrimary: IKButtonTheme.mail.disabledPrimary,
        disabledSecondary: IKButtonTheme.mail.disabledSecondary,
        error: IKButtonTheme.mail.error,
        smallFont: IKButtonTheme.mail.smallFont,
        mediumFont: IKButtonTheme.mail.mediumFont
    )
}