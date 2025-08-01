/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

public enum DestructiveActionAlertType {
    case permanentlyDelete(Int)
    case flushFolder(Folder?)
    case deleteSnooze(Int)
    case archiveSnooze(Int)
    case moveSnooze(Int)
    case deleteFolder(Folder)
}

public struct DestructiveActionAlertState: Identifiable, Equatable {
    public let id = UUID()
    public let type: DestructiveActionAlertType
    public let completion: () async -> Void

    public init(type: DestructiveActionAlertType, completion: @escaping () async -> Void) {
        self.type = type
        self.completion = completion
    }

    public static func == (lhs: DestructiveActionAlertState, rhs: DestructiveActionAlertState) -> Bool {
        return lhs.id == rhs.id
    }
}
