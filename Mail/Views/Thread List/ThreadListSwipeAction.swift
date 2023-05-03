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

private struct SwipeActionView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject private var mailboxManager: MailboxManager

    @Binding var moveAction: MoveAction?
    @Binding var actionsTarget: ActionsTarget?

    let thread: Thread
    let viewModel: ThreadListViewModel
    let action: SwipeAction

    var body: some View {
        Button(role: action.isDestructive ? .destructive : nil) {
            matomo.track(eventWithCategory: .swipeActions, name: action.matomoName)
            Task {
                await tryOrDisplayError {
                    try await handleSwipeAction(action, thread: thread)
                }
            }
        } label: {
            Label { Text(action.title) } icon: { action.icon(from: thread) }
                .labelStyle(.iconOnly)
        }
        .tint(action.swipeTint)
    }

    func handleSwipeAction(_ action: SwipeAction, thread: Thread) async throws {
        switch action {
        case .delete:
            try await mailboxManager.moveOrDelete(threads: [thread])
        case .archive:
            try await move(thread: thread, to: .archive)
        case .readUnread:
            try await mailboxManager.toggleRead(threads: [thread])
        case .move:
            moveAction = MoveAction(fromFolderId: viewModel.folder.id, target: .threads([thread], false))
        case .favorite:
            try await mailboxManager.toggleStar(threads: [thread])
        case .postPone:
            // TODO: Report action
            showWorkInProgressSnackBar()
        case .spam:
            try await toggleSpam(thread: thread)
        case .quickAction:
            actionsTarget = .threads([thread.thaw() ?? thread], false)
        case .none:
            break
        case .moveToInbox:
            try await move(thread: thread, to: .inbox)
        }
    }

    private func toggleSpam(thread: Thread) async throws {
        let destination: FolderRole = viewModel.folder.role == .spam ? .inbox : .spam
        try await move(thread: thread, to: destination)
    }

    private func move(thread: Thread, to folderRole: FolderRole) async throws {
        guard let folder = mailboxManager.getFolder(with: folderRole)?.freeze() else { return }
        try await move(thread: thread, to: folder)
    }

    private func move(thread: Thread, to folder: Folder) async throws {
        let response = try await mailboxManager.move(threads: [thread], to: folder)
        IKSnackBar.showCancelableSnackBar(message: MailResourcesStrings.Localizable.snackbarThreadMoved(folder.localizedName),
                                          cancelSuccessMessage: MailResourcesStrings.Localizable.snackbarMoveCancelled,
                                          undoRedoAction: response,
                                          mailboxManager: mailboxManager)
    }
}

struct ThreadListSwipeActions: ViewModifier {
    @AppStorage(UserDefaults.shared.key(.swipeFullLeading)) private var swipeFullLeading = DefaultPreferences.swipeFullLeading
    @AppStorage(UserDefaults.shared.key(.swipeLeading)) private var swipeLeading = DefaultPreferences.swipeLeading

    @AppStorage(UserDefaults.shared.key(.swipeFullTrailing)) private var swipeFullTrailing = DefaultPreferences.swipeFullTrailing
    @AppStorage(UserDefaults.shared.key(.swipeTrailing)) private var swipeTrailing = DefaultPreferences.swipeTrailing

    @State private var moveAction: MoveAction?
    @State private var actionsTarget: ActionsTarget?

    let thread: Thread
    let viewModel: ThreadListViewModel
    let multipleSelectionViewModel: ThreadListMultipleSelectionViewModel

    func body(content: Content) -> some View {
        if viewModel.folder.role == .draft {
            content
                .swipeActions(edge: .trailing) {
                    edgeActions([.delete])
                }
        } else {
            content
                .swipeActions(edge: .leading) {
                    edgeActions([swipeFullLeading, swipeLeading])
                }
                .swipeActions(edge: .trailing) {
                    edgeActions([swipeFullTrailing, swipeTrailing])
                }
                .actionsPanel(actionsTarget: $actionsTarget)
                .sheet(item: $moveAction) { moveAction in
                    MoveEmailView(moveAction: moveAction)
                        .sheetViewStyle()
                }
        }
    }

    @MainActor @ViewBuilder
    private func edgeActions(_ actions: [SwipeAction]) -> some View {
        if !multipleSelectionViewModel.isEnabled {
            ForEach(actions.filter { $0 != .none }, id: \.rawValue) { action in
                SwipeActionView(moveAction: $moveAction,
                                actionsTarget: $actionsTarget,
                                thread: thread,
                                viewModel: viewModel,
                                action: action)
            }
        }
    }
}

extension View {
    func swipeActions(thread: Thread,
                      viewModel: ThreadListViewModel,
                      multipleSelectionViewModel: ThreadListMultipleSelectionViewModel) -> some View {
        modifier(ThreadListSwipeActions(thread: thread,
                                        viewModel: viewModel,
                                        multipleSelectionViewModel: multipleSelectionViewModel))
    }
}

struct ThreadListSwipeAction_Previews: PreviewProvider {
    static var previews: some View {
        SwipeActionView(moveAction: .constant(nil),
                        actionsTarget: .constant(nil),
                        thread: PreviewHelper.sampleThread,
                        viewModel: ThreadListViewModel(mailboxManager: PreviewHelper.sampleMailboxManager,
                                                       folder: PreviewHelper.sampleFolder,
                                                       isCompact: false),
                        action: .delete)
    }
}
