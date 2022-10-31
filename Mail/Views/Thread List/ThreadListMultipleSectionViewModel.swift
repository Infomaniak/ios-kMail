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
import MailCore
import MailResources
import SwiftUI

@MainActor class ThreadListMultipleSelectionViewModel: ObservableObject {
    var mailboxManager: MailboxManager

    @Published var isEnabled = false {
        didSet {
            if !isEnabled {
                selectedItems = []
            }
        }
    }

    @Published var selectedItems = [Thread]()
    @Published var toolbarActions = [Action]()

    init(mailboxManager: MailboxManager) {
        self.mailboxManager = mailboxManager
        setActions()
    }

    func toggleSelection(of thread: Thread) {
        if selectedItems.contains(where: { $0.id == thread.id }) {
            selectedItems.removeAll { $0.id == thread.id }
        } else {
            selectedItems.append(thread)
        }
        setActions()
    }

    func didTap(action: Action) async throws {
        switch action {
        case .markAsRead, .markAsUnread:
            try await mailboxManager.toggleRead(threads: Array(selectedItems))
        case .archive:
            let undoRedoAction = try await mailboxManager.move(threads: Array(selectedItems), to: .archive)
            IKSnackBar.showCancelableSnackBar(message: MailResourcesStrings.Localizable.actionArchive,
                                              cancelSuccessMessage: MailResourcesStrings.Localizable.snackbarMoveCancelled,
                                              undoRedoAction: undoRedoAction,
                                              mailboxManager: mailboxManager)
        case .star:
            try await mailboxManager.toggleStar(threads: Array(selectedItems))
        case .delete:
            try await mailboxManager.moveOrDelete(threads: Array(selectedItems))
        default:
            break
        }
        withAnimation {
            isEnabled = false
        }
    }

    private func setActions() {
        let read = selectedItems.contains { $0.unseenMessages != 0 } ? Action.markAsRead : Action.markAsUnread
        toolbarActions = [read, .archive, .star, .delete]
    }
}
