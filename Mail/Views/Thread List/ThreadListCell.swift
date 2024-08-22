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
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailCoreUI
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
    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject private var splitViewManager: SplitViewManager
    @EnvironmentObject private var mainViewState: MainViewState

    let viewModel: ThreadListable
    @ObservedObject var multipleSelectionViewModel: MultipleSelectionViewModel

    let thread: Thread

    let threadDensity: ThreadDensity
    let accentColor: AccentColor

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
            isSelected: isMultiSelected,
            avatarTapped: {
                if multipleSelectionViewModel.isEnabled {
                    didTapCell()
                } else {
                    didOptionalTapCell()
                }
            }
        )
        .background(SelectionBackground(
            selectionType: selectionType,
            paddingLeading: 4,
            withAnimation: false,
            accentColor: accentColor
        ))
        .contentShape(Rectangle())
        .onTapGesture { didTapCell() }
        .openInWindowOnDoubleTap(
            windowId: DesktopWindowIdentifier.threadWindowIdentifier,
            value: OpenThreadIntent.openFromThreadCell(
                thread: thread,
                currentFolder: viewModel.frozenFolder,
                mailboxManager: viewModel.mailboxManager
            )
        )
        .actionsContextMenu(thread: thread)
        .onLongPressGesture { didOptionalTapCell() }
        .swipeActions(
            thread: thread,
            viewModel: viewModel,
            multipleSelectionViewModel: multipleSelectionViewModel,
            nearestFlushAlert: $flushAlert
        )
        .accessibilityAction(named: MailResourcesStrings.Localizable.enableMultiSelection) {
            didOptionalTapCell()
        }
    }

    private func didTapCell() {
        viewModel.addCurrentSearchTermToHistoryIfNeeded()
        if multipleSelectionViewModel.isEnabled {
            multipleSelectionViewModel.toggleSelection(of: thread)
        } else {
            if thread.shouldPresentAsDraft {
                DraftUtils.editDraft(
                    from: thread,
                    mailboxManager: viewModel.mailboxManager,
                    composeMessageIntent: $mainViewState.composeMessageIntent
                )
            } else {
                splitViewManager.adaptToProminentThreadView()

                viewModel.onTapCell(thread: thread)
                mainViewState.selectedThread = thread
            }
        }
    }

    private func didOptionalTapCell() {
        guard !multipleSelectionViewModel.isEnabled else { return }
        multipleSelectionViewModel.feedbackGenerator.prepare()
        let eventCategory: MatomoUtils.EventCategory = viewModel is SearchViewModel ? .searchMultiSelection : .multiSelection
        matomo.track(eventWithCategory: eventCategory, action: .longPress, name: "enable")
        multipleSelectionViewModel.feedbackGenerator.impactOccurred()
        multipleSelectionViewModel.toggleSelection(of: thread)
    }
}

#Preview {
    ThreadListCell(
        viewModel: ThreadListViewModel(mailboxManager: PreviewHelper.sampleMailboxManager,
                                       frozenFolder: PreviewHelper.sampleFolder,
                                       selectedThreadOwner: PreviewHelper.mockSelectedThreadOwner),
        multipleSelectionViewModel: MultipleSelectionViewModel(fromArchiveFolder: true),
        thread: PreviewHelper.sampleThread,
        threadDensity: .large,
        accentColor: .pink,
        isSelected: false,
        isMultiSelected: false,
        flushAlert: .constant(nil)
    )
}
