/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import SwiftUI

struct MultipleSelectedThread: Hashable {
    let id: String
    let thread: Thread

    init(thread: Thread) {
        id = thread.id
        self.thread = thread
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: MultipleSelectedThread, rhs: MultipleSelectedThread) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Set<MultipleSelectedThread> {
    var threads: [Thread] {
        map { $0.thread }
    }

    var ids: [String] {
        map { $0.id }
    }
}

@MainActor
class MultipleSelectionViewModel: ObservableObject {
    @LazyInjectService private var matomo: MatomoUtils

    var isEnabled: Bool {
        return !selectedItems.isEmpty
    }

    @Published var selectedItems = Set<MultipleSelectedThread>()
    @Published var toolbarActions = [Action]()

    let fromArchiveFolder: Bool
    let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    init(fromArchiveFolder: Bool = false) {
        self.fromArchiveFolder = fromArchiveFolder
        setActions()
    }

    func disable() {
        withAnimation {
            selectedItems.removeAll()
        }
    }

    func toggleSelection(of thread: Thread) {
        withAnimation(.default.speed(2)) {
            let multipleSelectedThread = MultipleSelectedThread(thread: thread)
            if let threadIndex = selectedItems.firstIndex(of: multipleSelectedThread) {
                selectedItems.remove(at: threadIndex)
            } else {
                selectedItems.insert(multipleSelectedThread)
            }
            setActions()
        }
    }

    func selectAll(threads: [Thread]) {
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred(intensity: 0.6)

        if threads.count == selectedItems.count {
            disable()
            matomo.track(eventWithCategory: .multiSelection, name: "none")
        } else {
            selectedItems = Set(threads.map { MultipleSelectedThread(thread: $0) })
            matomo.track(eventWithCategory: .multiSelection, name: "all")
        }
        setActions()
    }

    private func setActions() {
        let read = selectedItems.threads.contains { $0.unseenMessages != 0 } ? Action.markAsRead : Action.markAsUnread
        let star = selectedItems.threads.allSatisfy(\.flagged) ? Action.unstar : Action.star
        let archive = fromArchiveFolder ? Action.openMovePanel : Action.archive
        toolbarActions = [read, archive, star, .delete]
    }
}
