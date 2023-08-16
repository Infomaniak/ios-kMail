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

@MainActor
class ThreadListMultipleSelectionViewModel: ObservableObject {
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

    init() {
        setActions()
    }

    func toggleSelection(of thread: Thread) {
        if let threadIndex = selectedItems.firstIndex(of: thread) {
            selectedItems.remove(at: threadIndex)
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

    private func setActions() {
        let read = selectedItems.contains { $0.unseenMessages != 0 } ? Action.markAsRead : Action.markAsUnread
        let star = selectedItems.allSatisfy(\.flagged) ? Action.unstar : Action.star
        toolbarActions = [read, .archive, star, .delete]
    }
}
