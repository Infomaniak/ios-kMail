/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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

public enum DisplayDate: Sendable, Equatable {
    case normal(Date)
    case snoozed(Date)
    case scheduled(Date)

    public var date: Date {
        switch self {
        case .normal(let date):
            return date
        case .snoozed(let date):
            return date
        case .scheduled(let date):
            return date
        }
    }

    public var icon: Image? {
        switch self {
        case .normal:
            return nil
        case .snoozed:
            return MailResourcesAsset.alarmClockThick.swiftUIImage
        case .scheduled:
            return MailResourcesAsset.clockThick.swiftUIImage
        }
    }

    public var iconForeground: Color? {
        switch self {
        case .normal:
            return nil
        case .snoozed, .scheduled:
            return MailResourcesAsset.coralColor.swiftUIColor
        }
    }
}
