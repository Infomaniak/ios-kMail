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
import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import RealmSwift
import SwiftUI

enum ActionsTarget: Equatable, Identifiable {
    var id: String {
        switch self {
        case .threads(let threads, _):
            return threads.map(\.id).joined()
        case .message(let message):
            return message.uid
        }
    }

    case threads([Thread], Bool)
    case message(Message)

    var isInvalidated: Bool {
        switch self {
        case .threads(let threads, _):
            return threads.contains(where: \.isInvalidated)
        case .message(let message):
            return message.isInvalidated
        }
    }

    var messages: [Message] {
        switch self {
        case .threads(let threads, _):
            return threads.flatMap(\.messages).map { $0.freezeIfNeeded() }
        case .message(let message):
            return [message].map { $0.freezeIfNeeded() }
        }
    }

    func freeze() -> Self {
        switch self {
        case .threads(let threads, let isMultiSelectionEnabled):
            return .threads(threads.map { $0.freezeIfNeeded() }, isMultiSelectionEnabled)
        case .message(let message):
            return .message(message.freezeIfNeeded())
        }
    }
}
