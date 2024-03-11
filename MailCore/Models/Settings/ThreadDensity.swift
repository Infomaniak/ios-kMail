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

public enum ThreadDensity: String, CaseIterable, SettingsOptionEnum {
    case compact
    case normal
    case large

    public var title: String {
        switch self {
        case .compact:
            return MailResourcesStrings.Localizable.settingsDensityOptionCompact
        case .normal:
            return MailResourcesStrings.Localizable.settingsDensityOptionNormal
        case .large:
            return MailResourcesStrings.Localizable.settingsDensityOptionLarge
        }
    }

    public var image: Image? {
        let accentColor = UserDefaults.shared.accentColor
        let resource: MailResourcesImages
        switch self {
        case .normal:
            resource = accentColor.defaultListIcon
        case .large:
            resource = accentColor.largeListIcon
        case .compact:
            resource = accentColor.compactListIcon
        }
        return resource.swiftUIImage
    }

    public var hint: String? {
        return nil
    }
}
