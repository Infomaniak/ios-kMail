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

    @EnvironmentObject private var actionsManager: ActionsManager
    @EnvironmentObject private var navigationState: NavigationState

    @ObservedObject private var networkMonitor = NetworkMonitor.shared

    @Binding var actionPanelMessages: [Message]?
    @Binding var moveSheetMessages: [Message]?

    let thread: Thread
    let action: Action

    var body: some View {
        Button(role: action.isDestructive && networkMonitor.isConnected ? .destructive : nil) {
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
                            nearestFlushAlert: $navigationState.presentedFlushAlert
                        )
                    )
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
    @AppStorage(UserDefaults.shared.key(.swipeFullLeading)) private var swipeFullLeading = DefaultPreferences.swipeFullLeading
    @AppStorage(UserDefaults.shared.key(.swipeLeading)) private var swipeLeading = DefaultPreferences.swipeLeading

    @AppStorage(UserDefaults.shared.key(.swipeFullTrailing)) private var swipeFullTrailing = DefaultPreferences.swipeFullTrailing
    @AppStorage(UserDefaults.shared.key(.swipeTrailing)) private var swipeTrailing = DefaultPreferences.swipeTrailing

    @State private var actionPanelMessages: [Message]?
    @State private var moveSheetMessages: [Message]?

    let thread: Thread
    let viewModel: ThreadListViewModel
    let multipleSelectionViewModel: ThreadListMultipleSelectionViewModel

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading) {
                if viewModel.folder.role != .draft {
                    edgeActions([swipeFullLeading, swipeLeading])
                }
            }
            .swipeActions(edge: .trailing) {
                if viewModel.folder.role == .draft {
                    edgeActions([.delete])
                } else {
                    edgeActions([swipeFullTrailing, swipeTrailing])
                }
            }
            .actionsPanel(messages: $actionPanelMessages, originFolder: thread.folder)
    }

    @MainActor @ViewBuilder
    private func edgeActions(_ actions: [Action]) -> some View {
        if !multipleSelectionViewModel.isEnabled {
            ForEach(actions.filter { $0 != .noAction }.map { $0.inverseActionIfNeeded(for: thread) }) { action in
                SwipeActionView(
                    actionPanelMessages: $actionPanelMessages,
                    moveSheetMessages: $moveSheetMessages,
                    thread: thread,
                    action: action
                )
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
        SwipeActionView(
            actionPanelMessages: .constant(nil),
            moveSheetMessages: .constant(nil),
            thread: PreviewHelper.sampleThread,
            action: .delete
        )
    }
}
