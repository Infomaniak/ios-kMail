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

import MailCore
import SwiftUI

@MainActor
class SearchMultipleSelectionViewModel: ObservableObject {
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

    func toggleSelection(of thread: Thread) {
        if let threadIndex = selectedItems.firstIndex(of: thread) {
            selectedItems.remove(at: threadIndex)
            if selectedItems.isEmpty {
                isEnabled = false
            }
        } else {
            selectedItems.insert(thread)
        }
        setActions()
    }

    private func setActions() {
        let read = selectedItems.contains { $0.unseenMessages != 0 } ? Action.markAsRead : Action.markAsUnread
        let star = selectedItems.allSatisfy(\.flagged) ? Action.unstar : Action.star
        toolbarActions = [read, star, .delete]
    }
}
