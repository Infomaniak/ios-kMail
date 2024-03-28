/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import UIKit

/// The aim of the Action concept is to model quick actions the app supports and work with them safely when mapping between
/// UIApplicationShortcutItem.

/// We create and identify quick actions the app will perform
enum QuickActionType: String {
    case newMessage = "NewMessage"
    case search = "Search"
    case support = "Support"
}

/// We need the other enum to be Equatable to add other actions later
enum QuickAction: Equatable {
    case newMessage
    case search
    case support

    /// We create a failable initializer that accepts an instance of UIApplicationShortcutItem to let the system describe quick
    /// actions
    init?(shortcutItem: UIApplicationShortcutItem) {
        /// We ensure that you’re creating an Action for a known ActionType, otherwise we return nil.
        guard let type = QuickActionType(rawValue: shortcutItem.type) else {
            return nil
        }
        /// Switch on the different possible ActionType values known to the app.
        switch type {
        case .newMessage:
            self = .newMessage
        case .search:
            self = .search
        case .support:
            self = .support
        }
    }
}

/// We define an ObservableObject class we can later pass into the SwiftUI environment as well as provide a singleton accessor for
/// later when we work with UIKit code
// class QuickActionService: ObservableObject {
//    static let shared = QuickActionService()

/// We represent an action the app should perform
//    @Published var quickAction: QuickAction?
// }
