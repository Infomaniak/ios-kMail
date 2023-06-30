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

import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct ThreadListCell: View {
    @EnvironmentObject var splitViewManager: SplitViewManager
    @EnvironmentObject var navigationStore: NavigationStore

    let viewModel: ThreadListViewModel
    @ObservedObject var multipleSelectionViewModel: ThreadListMultipleSelectionViewModel

    let thread: Thread

    let threadDensity: ThreadDensity

    let isSelected: Bool
    let isMultiSelected: Bool

    private var selectionType: SelectionBackgroundKind {
        if multipleSelectionViewModel.isEnabled {
            return isMultiSelected ? .multiple : .none
        }
        return isSelected ? .single : .none
    }

    var body: some View {
        ThreadCell(
            thread: thread,
            density: threadDensity,
            isMultipleSelectionEnabled: multipleSelectionViewModel.isEnabled,
            isSelected: isMultiSelected
        )
        .background(SelectionBackground(selectionType: selectionType, paddingLeading: 4, withAnimation: false))
        .contentShape(Rectangle())
        .onTapGesture { didTapCell() }
        .onLongPressGesture { didLongPressCell() }
        .swipeActions(thread: thread, viewModel: viewModel, multipleSelectionViewModel: multipleSelectionViewModel)
        .threadListCellAppearance()
    }

    private func didTapCell() {
        if multipleSelectionViewModel.isEnabled {
            withAnimation(.default.speed(2)) {
                multipleSelectionViewModel.toggleSelection(of: thread)
            }
        } else {
            if thread.shouldPresentAsDraft {
                DraftUtils.editDraft(
                    from: thread,
                    mailboxManager: viewModel.mailboxManager,
                    editedMessageDraft: $navigationStore.editedMessageDraft
                )
            } else {
                splitViewManager.splitViewController?.hide(.primary)
                if splitViewManager.splitViewController?.splitBehavior == .overlay {
                    splitViewManager.splitViewController?.hide(.supplementary)
                }

                // Update both viewModel and navigationStore on the truth.
                viewModel.selectedThread = thread
                navigationStore.threadPath = [thread]
            }
        }
    }

    private func didLongPressCell() {
        multipleSelectionViewModel.feedbackGenerator.prepare()
        multipleSelectionViewModel.isEnabled.toggle()
        if multipleSelectionViewModel.isEnabled {
            @InjectService var matomo: MatomoUtils
            matomo.track(eventWithCategory: .multiSelection, action: .longPress, name: "enable")
            multipleSelectionViewModel.feedbackGenerator.impactOccurred()
            multipleSelectionViewModel.toggleSelection(of: thread)
        }
    }
}

struct ThreadListCell_Previews: PreviewProvider {
    static var previews: some View {
        ThreadListCell(
            viewModel: ThreadListViewModel(mailboxManager: PreviewHelper.sampleMailboxManager,
                                           folder: PreviewHelper.sampleFolder,
                                           isCompact: false),
            multipleSelectionViewModel: ThreadListMultipleSelectionViewModel(mailboxManager: PreviewHelper.sampleMailboxManager),
            thread: PreviewHelper.sampleThread,
            threadDensity: .large,
            isSelected: false,
            isMultiSelected: false
        )
    }
}
