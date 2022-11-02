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

import MailCore
import MailResources
import SwiftUI

struct ThreadListCell: View {
    @EnvironmentObject var splitViewManager: SplitViewManager

    let thread: Thread
    @ObservedObject var viewModel: ThreadListViewModel
    @ObservedObject var multipleSelectionViewModel: ThreadListMultipleSelectionViewModel

    let threadDensity: ThreadDensity
    let accentColor: AccentColor

    let navigationController: UINavigationController?

    @Binding var editedMessageDraft: Draft?

    @State private var shouldNavigateToThreadList = false

    private var cellColor: Color {
        return viewModel.selectedThread == thread
            ? MailResourcesAsset.backgroundCardSelectedColor.swiftUiColor
            : MailResourcesAsset.backgroundColor.swiftUiColor
    }

    private var isSelected: Bool {
        multipleSelectionViewModel.selectedItems.contains { $0.id == thread.id }
    }

    var body: some View {
        ZStack {
            if !thread.shouldPresentAsDraft {
                NavigationLink(destination: ThreadView(mailboxManager: viewModel.mailboxManager,
                                                       thread: thread,
                                                       folderId: viewModel.folder?.id,
                                                       trashFolderId: viewModel.trashFolderId,
                                                       navigationController: navigationController),
                               isActive: $shouldNavigateToThreadList) { EmptyView() }
                    .opacity(0)
                    .disabled(multipleSelectionViewModel.isEnabled)
            }

            ThreadCell(
                thread: thread,
                threadDensity: threadDensity,
                accentColor: accentColor,
                isMultipleSelectionEnabled: multipleSelectionViewModel.isEnabled,
                isSelected: isSelected
            )
        }
        .onAppear { viewModel.loadNextPageIfNeeded(currentItem: thread) }
        .padding(.leading, multipleSelectionViewModel.isEnabled ? 8 : 0)
        .padding(.vertical, -4)
        .onTapGesture { didTapCell() }
        .onLongPressGesture(minimumDuration: 0.3) { didLongPressCell() }
        .swipeActions(thread: thread, viewModel: viewModel, multipleSelectionViewModel: multipleSelectionViewModel)
        .background(SelectionBackground(isSelected: isSelected, offsetX: 8, leadingPadding: 0, verticalPadding: 2,
                                        defaultColor: cellColor))
        .clipped()
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowSeparator(.hidden)
        .listRowBackground(cellColor)
    }

    private func didTapCell() {
        if multipleSelectionViewModel.isEnabled {
            withAnimation(.default.speed(2)) {
                multipleSelectionViewModel.toggleSelection(of: thread)
            }
        } else {
            viewModel.selectedThread = thread
            splitViewManager.splitViewController?.hide(.primary)
            if splitViewManager.splitViewController?.splitBehavior == .overlay {
                splitViewManager.splitViewController?.hide(.supplementary)
            }
            if thread.shouldPresentAsDraft {
                DraftUtils.editDraft(
                    from: thread,
                    mailboxManager: viewModel.mailboxManager,
                    editedMessageDraft: $editedMessageDraft
                )
            } else {
                shouldNavigateToThreadList = true
            }
        }
    }

    private func didLongPressCell() {
        withAnimation {
            multipleSelectionViewModel.isEnabled.toggle()
            if multipleSelectionViewModel.isEnabled {
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
                                           folder: nil, bottomSheet: ThreadBottomSheet()),
            multipleSelectionViewModel: ThreadListMultipleSelectionViewModel(mailboxManager: PreviewHelper.sampleMailboxManager),
            threadDensity: .large,
            accentColor: .pink,
            navigationController: nil,
            editedMessageDraft: .constant(nil)
        )
    }
}
