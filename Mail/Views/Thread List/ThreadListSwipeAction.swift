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
import SwiftModalPresentation
import SwiftUI

private struct SwipeActionView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject private var actionsManager: ActionsManager

    @ObservedObject private var networkMonitor = NetworkMonitor.shared

    @Binding var actionPanelMessages: [Message]?
    @Binding var moveSheetMessages: [Message]?
    @Binding var flushAlert: FlushAlertState?

    let viewModel: ThreadListable
    let thread: Thread
    let action: Action

    private var isDestructive: Bool {
        let shouldWarnBeforeDeletion = thread.folder?.shouldWarnBeforeDeletion ?? false
        return action.isDestructive && networkMonitor.isConnected && !shouldWarnBeforeDeletion
    }

    var body: some View {
        Button(role: isDestructive ? .destructive : nil) {
            matomo.track(eventWithCategory: .swipeActions, action: .drag, name: action.matomoName)
            Task {
                await tryOrDisplayError {
                    try await actionsManager.performAction(
                        target: thread.messages.toArray(),
                        action: action,
                        origin: .swipe(
                            originFolder: thread.folder,
                            nearestMessagesActionsPanel: $actionPanelMessages,
                            nearestMessagesToMoveSheet: $moveSheetMessages,
                            nearestFlushAlert: $flushAlert
                        )
                    )

                    viewModel.refreshSearchIfNeeded(action: action)
                }
            }
        } label: {
            Label { Text(action.title) } icon: { action.icon }
                .labelStyle(.iconOnly)
        }
        .tint(action.tintColor)
    }
}

struct ThreadListSwipeActions: ViewModifier {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @AppStorage(UserDefaults.shared.key(.swipeFullLeading)) private var swipeFullLeading = DefaultPreferences.swipeFullLeading
    @AppStorage(UserDefaults.shared.key(.swipeLeading)) private var swipeLeading = DefaultPreferences.swipeLeading

    @AppStorage(UserDefaults.shared.key(.swipeFullTrailing)) private var swipeFullTrailing = DefaultPreferences.swipeFullTrailing
    @AppStorage(UserDefaults.shared.key(.swipeTrailing)) private var swipeTrailing = DefaultPreferences.swipeTrailing

    @State private var actionPanelMessages: [Message]?
    @ModalState private var messagesToMove: [Message]?

    let thread: Thread
    let viewModel: ThreadListable
    let multipleSelectionViewModel: MultipleSelectionViewModel

    @Binding var flushAlert: FlushAlertState?

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading) {
                if viewModel.frozenFolder.role != .draft {
                    edgeActions([swipeFullLeading, swipeLeading])
                }
            }
            .swipeActions(edge: .trailing) {
                if viewModel.frozenFolder.role == .draft {
                    edgeActions([.delete])
                } else {
                    edgeActions([swipeFullTrailing, swipeTrailing])
                }
            }
            .actionsPanel(messages: $actionPanelMessages, originFolder: thread.folder, panelSource: .threadList) { action in
                viewModel.refreshSearchIfNeeded(action: action)
            }
            .sheet(item: $messagesToMove) { messages in
                let originFolder: Folder? = viewModel is SearchViewModel ? viewModel.frozenFolder : thread.folder
                MoveEmailView(mailboxManager: mailboxManager, movedMessages: messages, originFolder: originFolder)
                    .sheetViewStyle()
            }
    }

    @MainActor @ViewBuilder
    private func edgeActions(_ actions: [Action]) -> some View {
        if !multipleSelectionViewModel.isEnabled {
            ForEach(actions.filter { $0 != .noAction }.map { $0.inverseActionIfNeeded(for: thread) }) { action in
                SwipeActionView(
                    actionPanelMessages: $actionPanelMessages,
                    moveSheetMessages: $messagesToMove,
                    flushAlert: $flushAlert,
                    viewModel: viewModel,
                    thread: thread,
                    action: action
                )
            }
        }
    }
}

extension View {
    func swipeActions(thread: Thread,
                      viewModel: ThreadListable,
                      multipleSelectionViewModel: MultipleSelectionViewModel,
                      nearestFlushAlert: Binding<FlushAlertState?>) -> some View {
        modifier(ThreadListSwipeActions(thread: thread,
                                        viewModel: viewModel,
                                        multipleSelectionViewModel: multipleSelectionViewModel,
                                        flushAlert: nearestFlushAlert))
    }
}

#Preview {
    SwipeActionView(
        actionPanelMessages: .constant(nil),
        moveSheetMessages: .constant(nil),
        flushAlert: .constant(nil),
        viewModel: ThreadListViewModel(mailboxManager: PreviewHelper.sampleMailboxManager,
                                       frozenFolder: PreviewHelper.sampleFolder,
                                       selectedThreadOwner: PreviewHelper.mockSelectedThreadOwner),
        thread: PreviewHelper.sampleThread,
        action: .delete
    )
}
