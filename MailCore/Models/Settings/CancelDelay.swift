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

public enum CancelDelay: Int, CaseIterable, SettingsOptionEnum {
    case disabled = 0
    case seconds10 = 10
    case seconds15 = 15
    case seconds20 = 20
    case seconds25 = 25
    case seconds30 = 30

    public var safeValue: Int {
        switch self {
        case .disabled:
            return rawValue
        default:
            return rawValue + 2
        }
    }

    public var title: String {
        return self == .disabled
            ? MailResourcesStrings.Localizable.settingsDisabled
            : MailResourcesStrings.Localizable.settingsDelaySeconds(rawValue)
    }

    public var image: Image? {
        return nil
    }

    public var hint: String? {
        return nil
    }

    public var matomoName: String {
        return "\(rawValue)s"
    }
}
