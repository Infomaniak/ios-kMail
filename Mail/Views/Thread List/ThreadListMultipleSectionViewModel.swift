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
import SwiftUI

@MainActor class ThreadListMultipleSelectionViewModel: ObservableObject {
    let mailboxManager: MailboxManager

    let flushAlert: FlushAlertState

    @Published var isEnabled = false {
        didSet {
            if !isEnabled {
                selectedItems = []
            }
        }
    }

    @Published var selectedItems = Set<Thread>()
    @Published var toolbarActions = [Action]()

    let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    init(mailboxManager: MailboxManager, flushAlert: FlushAlertState) {
        self.mailboxManager = mailboxManager
        self.flushAlert = flushAlert
        setActions()
    }

    func toggleSelection(of thread: Thread) {
        if selectedItems.contains(thread) {
            selectedItems.remove(thread)
        } else {
            selectedItems.insert(thread)
        }
        setActions()
    }

    func selectAll(threads: [Thread]) {
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred(intensity: 0.6)

        if threads.count == selectedItems.count {
            selectedItems.removeAll()
        } else {
            selectedItems = Set(threads)
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
            let threads = Array(self.selectedItems)
            if selectedItems.first?.folder?.role == .trash || selectedItems.first?.folder?.role == .spam {
                flushAlert.isShowing = true
                flushAlert.deletedMessages = selectedItems.count
                flushAlert.completion = {
                    Task {
                        try await self.mailboxManager.moveOrDelete(threads: threads)
                    }
                }
            } else {
                try await mailboxManager.moveOrDelete(threads: threads)
            }
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
