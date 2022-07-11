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

import Foundation
import MailResources
import SwiftUI

public extension MailResourcesColors {
    var swiftUiColor: SwiftUI.Color {
        return SwiftUI.Color(color)
    }
}

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
        return nil
    }

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

    public var longLeftIcon: MailResourcesImages {
        switch self {
        case .pink:
            return MailResourcesAsset.longLeftPink
        case .blue:
            return MailResourcesAsset.longLeftBlue
        }
    }

    public var longRightIcon: MailResourcesImages {
        switch self {
        case .pink:
            return MailResourcesAsset.longRightPink
        case .blue:
            return MailResourcesAsset.longRightBlue
        }
    }

    public var shortLeftIcon: MailResourcesImages {
        switch self {
        case .pink:
            return MailResourcesAsset.shortLeftPink
        case .blue:
            return MailResourcesAsset.shortLeftBlue
        }
    }

    public var shortRightIcon: MailResourcesImages {
        switch self {
        case .pink:
            return MailResourcesAsset.shortRightPink
        case .blue:
            return MailResourcesAsset.shortRightBlue
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

    // MARK: - List icons

    public var compactListIcon: MailResourcesImages {
         switch self {
         case .pink:
             return MailResourcesAsset.compactListPink
         case .blue:
             return MailResourcesAsset.compactListBlue
         }
     }

     public var defaultListIcon: MailResourcesImages {
         switch self {
         case .pink:
             return MailResourcesAsset.defaultListPink
         case .blue:
             return MailResourcesAsset.defaultListBlue
         }
     }

     public var largeListIcon: MailResourcesImages {
         switch self {
         case .pink:
             return MailResourcesAsset.largeListPink
         case .blue:
             return MailResourcesAsset.largeListBlue
         }
     }

    // MARK: - Onboarding illustration images

    public var onboardingIllu1: MailResourcesImages {
        switch self {
        case .pink:
            return MailResourcesAsset.onboardingIllu1Pink
        case .blue:
            return MailResourcesAsset.onboardingIllu1Blue
        }
    }

    public var onboardingIllu2: MailResourcesImages {
        switch self {
        case .pink:
            return MailResourcesAsset.onboardingIllu2Pink
        case .blue:
            return MailResourcesAsset.onboardingIllu2Blue
        }
    }

    public var onboardingIllu3: MailResourcesImages {
        switch self {
        case .pink:
            return MailResourcesAsset.onboardingIllu3Pink
        case .blue:
            return MailResourcesAsset.onboardingIllu3Blue
        }
    }

    public var onboardingIllu4: MailResourcesImages {
        switch self {
        case .pink:
            return MailResourcesAsset.onboardingIllu4Pink
        case .blue:
            return MailResourcesAsset.onboardingIllu4Blue
        }
    }
}
