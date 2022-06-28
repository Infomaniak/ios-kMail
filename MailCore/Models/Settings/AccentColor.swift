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
            return MailResourcesStrings.accentColorPinkTitle
        case .blue:
            return MailResourcesStrings.accentColorBlueTitle
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
}
