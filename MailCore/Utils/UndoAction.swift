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

@frozen public struct UndoAction {
    public typealias UndoBlock = () async throws -> Bool

    public let undo: UndoBlock
    public let afterUndo: UndoBlock?

    public init(undo: @escaping UndoBlock, afterUndo: UndoBlock?) {
        self.undo = undo
        self.afterUndo = afterUndo
    }

    public init(waitingForAsyncUndoAction: Task<UndoAction, any Error>) {
        undo = {
            let undoAction = try await waitingForAsyncUndoAction.value
            return try await undoAction.undo()
        }

        afterUndo = {
            let undoAction = try await waitingForAsyncUndoAction.value
            guard let afterUndo = undoAction.afterUndo else {
                return true
            }

            return try await afterUndo()
        }
    }
}
