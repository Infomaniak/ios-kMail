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
import MailCoreUI
import SwiftModalPresentation
import SwiftUI

private struct SwipeActionView: View {
    @EnvironmentObject private var actionsManager: ActionsManager

    @ObservedObject private var networkMonitor = NetworkMonitor.shared

    @Binding var actionPanelMessages: [Message]?
    @Binding var moveSheetMessages: [Message]?
    @Binding var destructiveAlert: DestructiveActionAlertState?
    @Binding var nearestMessagesToSnooze: [Message]?

    let viewModel: ThreadListable
    let thread: Thread
    let action: Action

    private var isDestructive: Bool {
        guard networkMonitor.isConnected else { return false }
        return action.isDestructive(for: thread)
    }

    var body: some View {
        Button(role: isDestructive ? .destructive : nil) {
            @InjectService var matomo: MatomoUtils
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
                            nearestDestructiveAlert: $destructiveAlert,
                            nearestMessagesToSnooze: $nearestMessagesToSnooze
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
        .accessibilityIdentifier(action.accessibilityIdentifier)
    }
}

struct ThreadListSwipeActions: ViewModifier {
    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var mainViewState: MainViewState

    @AppStorage(UserDefaults.shared.key(.swipeFullLeading)) private var swipeFullLeading = DefaultPreferences.swipeFullLeading
    @AppStorage(UserDefaults.shared.key(.swipeLeading)) private var swipeLeading = DefaultPreferences.swipeLeading

    @AppStorage(UserDefaults.shared.key(.swipeFullTrailing)) private var swipeFullTrailing = DefaultPreferences.swipeFullTrailing
    @AppStorage(UserDefaults.shared.key(.swipeTrailing)) private var swipeTrailing = DefaultPreferences.swipeTrailing

    @State private var actionPanelMessages: [Message]?
    @ModalState private var messagesToMove: [Message]?
    @ModalState private var messagesToSnooze: [Message]?

    let thread: Thread
    let viewModel: ThreadListable
    let multipleSelectionViewModel: MultipleSelectionViewModel

    private var folder: Folder? {
        return viewModel is SearchViewModel ? viewModel.frozenFolder : thread.folder
    }

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading) {
                if !viewModel.frozenFolder.hasLimitedSwipeActions {
                    edgeActions([swipeFullLeading, swipeLeading])
                }
            }
            .swipeActions(edge: .trailing) {
                if viewModel.frozenFolder.hasLimitedSwipeActions {
                    edgeActions([.delete])
                } else {
                    edgeActions([swipeFullTrailing, swipeTrailing])
                }
            }
            .actionsPanel(
                messages: $actionPanelMessages,
                originFolder: thread.folder,
                panelSource: .threadList,
                popoverArrowEdge: .leading
            ) { action in
                viewModel.refreshSearchIfNeeded(action: action)
            }
            .sheet(item: $messagesToMove) { messages in
                MoveEmailView(mailboxManager: mailboxManager, movedMessages: messages, originFolder: folder)
                    .sheetViewStyle()
            }
            .snoozedFloatingPanel(
                messages: messagesToSnooze,
                initialDate: nil,
                folder: folder
            ) { messagesToSnooze = nil }
    }

    @MainActor @ViewBuilder
    private func edgeActions(_ actions: [Action]) -> some View {
        if !multipleSelectionViewModel.isEnabled {
            ForEach(filterAvailableActions(actions)) { action in
                SwipeActionView(
                    actionPanelMessages: $actionPanelMessages,
                    moveSheetMessages: $messagesToMove,
                    destructiveAlert: $mainViewState.destructiveAlert,
                    nearestMessagesToSnooze: $messagesToSnooze,
                    viewModel: viewModel,
                    thread: thread,
                    action: action
                )
            }
        }
    }

    private func filterAvailableActions(_ actions: [Action]) -> [Action] {
        let realActions = actions.map { $0.inverseActionIfNeeded(for: thread) }
        let availableActions = realActions.filter { action in
            switch action {
            case .noAction:
                return false
            case .snooze:
                return folder?.canAccessSnoozeActions == true
            default:
                return true
            }
        }

        return availableActions
    }
}

extension View {
    func swipeActions(thread: Thread,
                      viewModel: ThreadListable,
                      multipleSelectionViewModel: MultipleSelectionViewModel) -> some View {
        modifier(ThreadListSwipeActions(thread: thread,
                                        viewModel: viewModel,
                                        multipleSelectionViewModel: multipleSelectionViewModel))
    }
}

#Preview {
    SwipeActionView(
        actionPanelMessages: .constant(nil),
        moveSheetMessages: .constant(nil),
        destructiveAlert: .constant(nil),
        nearestMessagesToSnooze: .constant(nil),
        viewModel: ThreadListViewModel(mailboxManager: PreviewHelper.sampleMailboxManager,
                                       frozenFolder: PreviewHelper.sampleFolder,
                                       selectedThreadOwner: PreviewHelper.mockSelectedThreadOwner),
        thread: PreviewHelper.sampleThread,
        action: .delete
    )
}
