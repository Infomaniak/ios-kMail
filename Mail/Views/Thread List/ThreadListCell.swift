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

extension ThreadListCell: Equatable {
    static func == (lhs: ThreadListCell, rhs: ThreadListCell) -> Bool {
        return lhs.thread.id == rhs.thread.id
            && lhs.thread.messageIds == rhs.thread.messageIds
            && lhs.isSelected == rhs.isSelected
            && lhs.isMultiSelected == rhs.isMultiSelected
    }
}

struct ThreadListCell: View {
    @EnvironmentObject var splitViewManager: SplitViewManager
    @EnvironmentObject var navigationState: NavigationState

    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    let viewModel: ThreadListViewModel
    @ObservedObject var multipleSelectionViewModel: ThreadListMultipleSelectionViewModel

    let thread: Thread

    let threadDensity: ThreadDensity

    let isSelected: Bool
    let isMultiSelected: Bool

    @Binding var flushAlert: FlushAlertState?

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
            accentColor: accentColor,
            isMultipleSelectionEnabled: multipleSelectionViewModel.isEnabled,
            isSelected: isMultiSelected
        )
        .background(SelectionBackground(
            selectionType: selectionType,
            paddingLeading: 4,
            withAnimation: false,
            accentColor: accentColor
        ))
        .contentShape(Rectangle())
        .onTapGesture { didTapCell() }
        .onLongPressGesture { didLongPressCell() }
        .swipeActions(
            thread: thread,
            viewModel: viewModel,
            multipleSelectionViewModel: multipleSelectionViewModel,
            nearestFlushAlert: $flushAlert
        )
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
                    editedDraft: $navigationState.editedDraft
                )
            } else {
                splitViewManager.adaptToProminentThreadView()

                // Update both viewModel and navigationState on the truth.
                viewModel.selectedThread = thread
                navigationState.threadPath = [thread]
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
            multipleSelectionViewModel: ThreadListMultipleSelectionViewModel(),
            thread: PreviewHelper.sampleThread,
            threadDensity: .large,
            isSelected: false,
            isMultiSelected: false,
            flushAlert: .constant(nil)
        )
    }
}
