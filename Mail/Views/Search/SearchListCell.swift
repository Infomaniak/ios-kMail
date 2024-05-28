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

import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailCoreUI
import SwiftUI

struct SearchListCell: View {
    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject private var splitViewManager: SplitViewManager
    @EnvironmentObject private var mainViewState: MainViewState

    let viewModel: SearchViewModel
    @ObservedObject var multipleSelectionViewModel: SearchMultipleSelectionViewModel

    let thread: Thread

    let threadDensity: ThreadDensity
    let accentColor: AccentColor

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
            accentColor: accentColor,
            isMultipleSelectionEnabled: multipleSelectionViewModel.isEnabled,
            isSelected: isMultiSelected
        ) {
            if multipleSelectionViewModel.isEnabled {
                didTapCell()
            } else {
                didOptionalTapCell()
            }
        }
        .background(SelectionBackground(
            selectionType: selectionType,
            paddingLeading: 4,
            withAnimation: false,
            accentColor: accentColor
        ))
        .contentShape(Rectangle())
        .onTapGesture {
            didTapCell()
        }
        .actionsContextMenu(thread: thread)
        .onLongPressGesture {
            didOptionalTapCell()
        }
        .threadListCellAppearance()
    }

    private func didTapCell() {
        viewModel.addToHistoryIfNeeded()
        if multipleSelectionViewModel.isEnabled {
            withAnimation(.default.speed(2)) {
                multipleSelectionViewModel.toggleSelection(of: thread)
            }
        } else {
            if thread.shouldPresentAsDraft {
                DraftUtils.editDraft(
                    from: thread,
                    mailboxManager: viewModel.mailboxManager,
                    composeMessageIntent: $mainViewState.composeMessageIntent
                )
            } else {
                splitViewManager.adaptToProminentThreadView()

                mainViewState.selectedThread = thread
                viewModel.selectedThread = thread
            }
        }
    }

    private func didOptionalTapCell() {
        guard !multipleSelectionViewModel.isEnabled else { return }
        multipleSelectionViewModel.feedbackGenerator.prepare()
        multipleSelectionViewModel.isEnabled = true
        matomo.track(eventWithCategory: .searchMultiSelection, action: .longPress, name: "enable")
        multipleSelectionViewModel.feedbackGenerator.impactOccurred()
        multipleSelectionViewModel.toggleSelection(of: thread)
    }
}

#Preview {
    SearchListCell(
        viewModel: SearchViewModel(mailboxManager: PreviewHelper.sampleMailboxManager, folder: PreviewHelper.sampleFolder),
        multipleSelectionViewModel: SearchMultipleSelectionViewModel(),
        thread: PreviewHelper.sampleThread,
        threadDensity: .large,
        accentColor: .pink,
        isSelected: false,
        isMultiSelected: false
    )
}
