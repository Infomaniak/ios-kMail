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
import MailResources
import SwiftUI
import MailCore

@MainActor class ThreadListMultipleSelectionViewModel: ObservableObject {
    var mailboxManager: MailboxManager

    @Published var isEnabled = false {
        didSet {
            if !isEnabled {
                selectedItems = Set<Thread>()
            }
        }
    }
    @Published var selectedItems = Set<Thread>()

    let toolbarActions: [Action] = [.markAsRead, .archive, .star, .delete]

    init(mailboxManager: MailboxManager) {
        self.mailboxManager = mailboxManager
    }

    func toggleSelection(of thread: Thread) {
        if selectedItems.contains(thread) {
            selectedItems.remove(thread)
        } else {
            selectedItems.insert(thread)
        }
    }

    func didTap(action: Action) async throws {
        switch action {
        case .markAsRead, .markAsUnread:
            try await mailboxManager.toggleRead(threads: Array(selectedItems))
        case .archive:
            let undoResponse = try await mailboxManager.move(messages: selectedItems.flatMap(\.messages), to: .archive)
            IKSnackBar.showCancelableSnackBar(message: MailResourcesStrings.Localizable.actionArchive,
                                              cancelSuccessMessage: MailResourcesStrings.Localizable.snackbarMoveCancelled,
                                              cancelableResponse: undoResponse,
                                              mailboxManager: mailboxManager)
        case .star, .unstar:
            try await mailboxManager.toggleStar(threads: Array(selectedItems))
        case .delete:
            try await mailboxManager.moveOrDelete(threads: Array(selectedItems))
        default:
            break
        }
        isEnabled = false
    }
}
