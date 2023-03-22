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

    let thread: Thread

    @ObservedObject var viewModel: ThreadListViewModel
    @ObservedObject var multipleSelectionViewModel: ThreadListMultipleSelectionViewModel

    let threadDensity: ThreadDensity

    let isSelected: Bool

    @Binding var editedMessageDraft: Draft?

    @State private var shouldNavigateToThreadList = false

    private var selectionType: SelectionBackgroundKind {
        if isSelected {
            return .multiple
        } else if !multipleSelectionViewModel.isEnabled && viewModel.selectedThread?.uid == thread.uid {
            return .single
        }
        return .none
    }

    private var selectedThreadBackground: Bool {
        return !multipleSelectionViewModel.isEnabled && (viewModel.selectedThread?.uid == thread.uid)
    }

    var body: some View {
        ZStack {
            if !thread.shouldPresentAsDraft {
                NavigationLink(destination: ThreadView(mailboxManager: viewModel.mailboxManager,
                                                       thread: thread,
                                                       onDismiss: { viewModel.selectedThread = nil }),
                               isActive: $shouldNavigateToThreadList) { EmptyView() }
                    .opacity(0)
                    .disabled(multipleSelectionViewModel.isEnabled)
            }

            ThreadCell(
                thread: thread,
                mailboxManager: viewModel.mailboxManager,
                density: threadDensity,
                isMultipleSelectionEnabled: multipleSelectionViewModel.isEnabled,
                isSelected: isSelected
            )
        }
        .background(SelectionBackground(selectionType: selectionType, paddingLeading: 4))
        .onTapGesture { didTapCell() }
        .onLongPressGesture(minimumDuration: 0.3) { didLongPressCell() }
        .swipeActions(thread: thread, viewModel: viewModel, multipleSelectionViewModel: multipleSelectionViewModel)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowSeparator(.hidden)
        .listRowBackground(MailResourcesAsset.backgroundColor.swiftUIColor)
        .onChange(of: viewModel.selectedThread) { newThread in
            if newThread?.uid == thread.uid {
                shouldNavigateToThreadList = true
            }
        }
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
                    editedMessageDraft: $editedMessageDraft
                )
            } else {
                splitViewManager.splitViewController?.hide(.primary)
                if splitViewManager.splitViewController?.splitBehavior == .overlay {
                    splitViewManager.splitViewController?.hide(.supplementary)
                }
                viewModel.selectedThread = thread
                shouldNavigateToThreadList = true
            }
        }
    }

    private func didLongPressCell() {
        withAnimation {
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
}

struct ThreadListCell_Previews: PreviewProvider {
    static var previews: some View {
        ThreadListCell(
            thread: PreviewHelper.sampleThread,
            viewModel: ThreadListViewModel(mailboxManager: PreviewHelper.sampleMailboxManager,
                                           folder: nil,
                                           bottomSheet: ThreadBottomSheet(),
                                           moveSheet: MoveSheet(),
                                           isCompact: false),
            multipleSelectionViewModel: ThreadListMultipleSelectionViewModel(mailboxManager: PreviewHelper.sampleMailboxManager),
            threadDensity: .large,
            isSelected: false,
            editedMessageDraft: .constant(nil)
        )
    }
}
