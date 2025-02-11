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

import Foundation
import MailResources
import SwiftUI

public enum AccentColor: String, CaseIterable, SettingsOptionEnum {
    case pink, blue

    public var title: String {
        switch self {
        case .pink:
            return MailResourcesStrings.Localizable.accentColorPinkTitle
        case .blue:
            return MailResourcesStrings.Localizable.accentColorBlueTitle
        }
    }

    public var image: Image? {
        switch self {
        case .pink:
            return MailResourcesAsset.colorPink.swiftUIImage
        case .blue:
            return MailResourcesAsset.colorBlue.swiftUIImage
        }
    }

    public var hint: String? {
        return nil
    }

    // MARK: - Colors

    public var primary: MailResourcesColors {
        switch self {
        case .pink:
            return MailResourcesAsset.primaryPinkColor
        case .blue:
            return MailResourcesAsset.primaryBlueColor
        }
    }

    public var secondary: MailResourcesColors {
        switch self {
        case .pink:
            return MailResourcesAsset.secondaryPinkColor
        case .blue:
            return MailResourcesAsset.secondaryBlueColor
        }
    }

    public var onAccent: MailResourcesColors {
        switch self {
        case .pink:
            return MailResourcesAsset.onAccentPinkColor
        case .blue:
            return MailResourcesAsset.onAccentBlueColor
        }
    }

    public var navBarBackground: MailResourcesColors {
        switch self {
        case .pink:
            return MailResourcesAsset.backgroundPinkNavBarColor
        case .blue:
            return MailResourcesAsset.backgroundBlueNavBarColor
        }
    }

    public var snackbarActionColor: MailResourcesColors {
        switch self {
        case .pink:
            return MailResourcesAsset.snackbarActionPinkColor
        case .blue:
            return MailResourcesAsset.snackbarActionBlueColor
        }
    }

    // MARK: - Images

    public var emptyThreadImage: MailResourcesImages {
        switch self {
        case .pink:
            return MailResourcesAsset.emptyStateSearchPink
        case .blue:
            return MailResourcesAsset.emptyStateSearchBlue
        }
    }

    public var createAccountImage: MailResourcesImages {
        switch self {
        case .pink:
            return MailResourcesAsset.createAccountPink
        case .blue:
            return MailResourcesAsset.createAccountBlue
        }
    }

    public var defaultApp: MailResourcesImages {
        switch self {
        case .pink:
            return MailResourcesAsset.defaultAppPink
        case .blue:
            return MailResourcesAsset.defaultAppBlue
        }
    }

    public var mailboxImage: MailResourcesImages {
        switch self {
        case .pink:
            return MailResourcesAsset.mailboxPink
        case .blue:
            return MailResourcesAsset.mailboxBlue
        }
    }

    public var dataPrivacyImage: MailResourcesImages {
        switch self {
        case .pink:
            return MailResourcesAsset.documentSignaturePencilBulbPink
        case .blue:
            return MailResourcesAsset.documentSignaturePencilBulbBlue
        }
    }

    // MARK: Swipe settings icons

    public var fullTrailingIcon: MailResourcesImages {
        switch self {
        case .pink:
            return MailResourcesAsset.longLeftPink
        case .blue:
            return MailResourcesAsset.longLeftBlue
        }
    }

    public var fullLeadingIcon: MailResourcesImages {
        switch self {
        case .pink:
            return MailResourcesAsset.longRightPink
        case .blue:
            return MailResourcesAsset.longRightBlue
        }
    }

    public var trailingIcon: MailResourcesImages {
        switch self {
        case .pink:
            return MailResourcesAsset.shortLeftPink
        case .blue:
            return MailResourcesAsset.shortLeftBlue
        }
    }

    public var leadingIcon: MailResourcesImages {
        switch self {
        case .pink:
            return MailResourcesAsset.shortRightPink
        case .blue:
            return MailResourcesAsset.shortRightBlue
        }
    }

    // MARK: List icons

    public var compactListIcon: MailResourcesImages {
        switch self {
        case .pink:
            return MailResourcesAsset.densityCompactPink
        case .blue:
            return MailResourcesAsset.densityCompactBlue
        }
    }

    public var defaultListIcon: MailResourcesImages {
        switch self {
        case .pink:
            return MailResourcesAsset.densityNormalPink
        case .blue:
            return MailResourcesAsset.densityNormalBlue
        }
    }

    public var largeListIcon: MailResourcesImages {
        switch self {
        case .pink:
            return MailResourcesAsset.densityLargePink
        case .blue:
            return MailResourcesAsset.densityLargeBlue
        }
    }
}
