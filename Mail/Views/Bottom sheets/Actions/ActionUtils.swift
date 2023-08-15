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
import InfomaniakCoreUI
import MailCore
import MailResources

struct ActionUtils {
    let actionsTarget: ActionsTarget
    let mailboxManager: MailboxManager

    func move(to folder: Folder) async throws {
        let undoAction: UndoAction
        let snackBarMessage: String
        switch actionsTarget {
        case .threads(let threads, _):
            guard threads.first?.folder != folder else { return }
            undoAction = try await mailboxManager.move(threads: threads, to: folder)
            snackBarMessage = MailResourcesStrings.Localizable.snackbarThreadsMoved(folder.localizedName)
        case .message(let message):
            guard message.folderId != folder.id else { return }
            var messages = [message]
            messages.append(contentsOf: message.duplicates)
            undoAction = try await mailboxManager.move(messages: messages, to: folder)
            snackBarMessage = MailResourcesStrings.Localizable.snackbarMessageMoved(folder.localizedName)
        }

        await IKSnackBar.showCancelableSnackBar(message: snackBarMessage,
                                                cancelSuccessMessage: MailResourcesStrings.Localizable.snackbarMoveCancelled,
                                                undoAction: undoAction,
                                                mailboxManager: mailboxManager)
    }

    func move(to folderRole: FolderRole) async throws {
        guard let folder = mailboxManager.getFolder(with: folderRole)?.freeze() else { return }
        try await move(to: folder)
    }
}
