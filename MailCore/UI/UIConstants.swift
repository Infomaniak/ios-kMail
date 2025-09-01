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

import MailResources
import SwiftUI

public enum UIConstants {}

// MARK: - Color sets

public extension UIConstants {
    static let avatarColors = [
        MailResourcesAsset.yellowColor,
        MailResourcesAsset.coralColor,
        MailResourcesAsset.grassColor,
        MailResourcesAsset.fougereColor,
        MailResourcesAsset.cobaltColor,
        MailResourcesAsset.jeanColor,
        MailResourcesAsset.tropicalColor,
        MailResourcesAsset.mauveColor,
        MailResourcesAsset.princeColor
    ].map(\.swiftUIColor)
}

// MARK: - Elements sizing

public extension UIConstants {
    static let onboardingLogoHeight: CGFloat = 56

    static let buttonsRadius: CGFloat = 16

    static let componentsMaxWidth: CGFloat = 496

    static let avatarBorderLineWidth: CGFloat = 1
}

// MARK: - Animations

public extension UIConstants {
    static var modalCloseDelay: DispatchTime {
        DispatchTime.now() + 0.75
    }
}

// MARK: - Utils

public extension UIConstants {
    static func isCompact(horizontalSizeClass: UserInterfaceSizeClass?, verticalSizeClass: UserInterfaceSizeClass?) -> Bool {
        return horizontalSizeClass == .compact || verticalSizeClass == .compact
    }
}
