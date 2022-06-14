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
    case defaultDensity
    case largeDensity
    case compactDensity

    public var title: String {
        switch self {
        case .defaultDensity:
            return MailResourcesStrings.settingsDefault
        case .largeDensity:
            return MailResourcesStrings.settingsDensityOptionLarge
        case .compactDensity:
            return MailResourcesStrings.settingsDensityOptionCompact
        }
    }

    public var image: Image? {
        switch self {
        case .defaultDensity:
            return Image(uiImage: MailResourcesAsset.defaultList.image)
        case .largeDensity:
            return Image(uiImage: MailResourcesAsset.normalList.image)
        case .compactDensity:
            return Image(uiImage: MailResourcesAsset.compactList.image)
        }
    }
}
