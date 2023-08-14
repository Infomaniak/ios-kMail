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

public enum SwipeType: String, CaseIterable {
    case leading
    case fullLeading
    case trailing
    case fullTrailing

    public typealias SwipeActionKeyPath = ReferenceWritableKeyPath<UserDefaults, Action>

    public var title: String {
        switch self {
        case .leading:
            return MailResourcesStrings.Localizable.settingsSwipeShortRight
        case .fullLeading:
            return MailResourcesStrings.Localizable.settingsSwipeLongRight
        case .trailing:
            return MailResourcesStrings.Localizable.settingsSwipeShortLeft
        case .fullTrailing:
            return MailResourcesStrings.Localizable.settingsSwipeLongLeft
        }
    }

    public var keyPath: SwipeActionKeyPath {
        switch self {
        case .leading:
            return \.swipeLeading
        case .fullLeading:
            return \.swipeFullLeading
        case .trailing:
            return \.swipeTrailing
        case .fullTrailing:
            return \.swipeFullTrailing
        }
    }

    public var excludedKeyPaths: [SwipeActionKeyPath] {
        switch self {
        case .leading:
            return [\.swipeFullLeading]
        case .fullLeading:
            return [\.swipeLeading]
        case .trailing:
            return [\.swipeFullTrailing]
        case .fullTrailing:
            return [\.swipeTrailing]
        }
    }
}
