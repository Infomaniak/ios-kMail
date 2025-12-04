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

import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import SwiftUI

@MainActor
class MultipleSelectionViewModel: ObservableObject {
    @LazyInjectService private var matomo: MatomoUtils

    @Published var isEnabled = false
    @Published var selectedItems = [String: Thread]()
    @Published var toolbarActions = [Action]()

    let fromArchiveFolder: Bool
    let fromSearch: Bool
    let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    init(fromArchiveFolder: Bool = false, fromSearch: Bool = false) {
        self.fromArchiveFolder = fromArchiveFolder
        self.fromSearch = fromSearch
        setActions()
    }

    func disable() {
        withAnimation {
            selectedItems.removeAll()
            isEnabled = false
        }
    }

    func toggleMultipleSelection(of thread: Thread, withImpact: Bool = false) {
        let eventCategory: MatomoUtils.EventCategory = fromSearch ? .searchMultiSelection : .multiSelection
        matomo.track(eventWithCategory: eventCategory, action: .longPress, name: "enable")
        if withImpact {
            feedbackGenerator.prepare()
            feedbackGenerator.impactOccurred()
        }
        toggleSelection(of: thread)
    }

    func toggleSelection(of thread: Thread) {
        withAnimation(.default.speed(2)) {
            if selectedItems[thread.uid] != nil {
                selectedItems.removeValue(forKey: thread.uid)
            } else {
                selectedItems[thread.uid] = thread
            }
            setActions()

            updateEnabledState()
        }
    }

    private func updateEnabledState() {
        if #available(iOS 18, *) {
            isEnabled = !selectedItems.isEmpty
        } else {
            /*
             Workaround under iOS 18, the last touch would deselect last item but also navigate.
             We disable selection state only on next run loop to avoid this issue.
             */
            if selectedItems.isEmpty {
                Task { @MainActor in
                    withAnimation {
                        isEnabled = false
                    }
                }
            } else {
                isEnabled = true
            }
        }
    }

    func selectAll(threads: [Thread]) {
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred(intensity: 0.6)

        if threads.count == selectedItems.count {
            disable()
            matomo.track(eventWithCategory: .multiSelection, name: "none")
        } else {
            selectedItems = Dictionary(uniqueKeysWithValues: threads.map { ($0.uid, $0) })
            matomo.track(eventWithCategory: .multiSelection, name: "all")
        }
        setActions()
    }

    private func setActions() {
        let read = selectedItems.values.contains { $0.unseenMessages != 0 } ? Action.markAsRead : Action.markAsUnread
        let star = selectedItems.values.allSatisfy(\.flagged) ? Action.unstar : Action.star
        let archive = fromArchiveFolder ? Action.openMovePanel : Action.archive
        toolbarActions = [read, archive, star, .delete]
    }
}
