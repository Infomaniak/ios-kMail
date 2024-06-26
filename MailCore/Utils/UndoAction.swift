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

    /// A block that executes the undo action
    public let undo: UndoBlock
    /// An optional block to executes something after the undo is done
    public let afterUndo: UndoBlock?

    public init(undo: @escaping UndoBlock, afterUndo: UndoBlock?) {
        self.undo = undo
        self.afterUndo = afterUndo
    }

    /// A convenience init for when we need to wait on an async call to be done but we want to update the UI without waiting
    ///
    /// For example: We need to wait for an `undoResource` when moving messages to undo the move but we want to present the
    /// snackbar without waiting
    public init(waitingForAsyncUndoAction: Task<UndoAction, any Error>) {
        // In this context, undoing is simply waiting to get the original UndoAction and then calling the original undo
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
