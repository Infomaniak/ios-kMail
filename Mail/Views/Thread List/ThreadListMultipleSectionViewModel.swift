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
import SwiftUI

@MainActor class ThreadListMultipleSelectionViewModel: ObservableObject {
    let mailboxManager: MailboxManager

    @LazyInjectService private var matomo: MatomoUtils

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

    init(mailboxManager: MailboxManager) {
        self.mailboxManager = mailboxManager
        setActions()
    }

    func toggleSelection(of thread: Thread) {
        if let thread = selectedItems.first(where: { $0.id == thread.id }) {
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
            matomo.track(eventWithCategory: .multiSelection, name: "none")
        } else {
            selectedItems = Set(threads)
            matomo.track(eventWithCategory: .multiSelection, name: "all")
        }
        setActions()
    }

    func didTap(action: Action, flushAlert: Binding<FlushAlertState?>) async throws {
        if let matomoName = action.matomoName {
            matomo.trackBulkEvent(eventWithCategory: .threadActions, name: matomoName, numberOfItems: selectedItems.count)
        }
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
            let threads = Array(selectedItems)
            switch selectedItems.first?.folder?.role {
            case .draft, .spam, .trash:
                flushAlert.wrappedValue = FlushAlertState(deletedMessages: selectedItems.count) {
                    await tryOrDisplayError {
                        try await self.mailboxManager.moveOrDelete(threads: threads)
                    }
                }
            default:
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
        let star = selectedItems.allSatisfy(\.flagged) ? Action.unstar : Action.star
        toolbarActions = [read, .archive, star, .delete]
    }
}
