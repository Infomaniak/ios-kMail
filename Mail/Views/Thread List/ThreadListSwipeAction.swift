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
    private let thread: Thread
    private let viewModel: ThreadListViewModel
    private let action: SwipeAction

    @LazyInjectService private var matomo: MatomoUtils

    init(thread: Thread, viewModel: ThreadListViewModel, action: SwipeAction) {
        self.thread = thread
        self.viewModel = viewModel
        self.action = action.fallback(for: thread) ?? action
    }

    var body: some View {
        Button(role: action.isDestructive ? .destructive : nil) {
            matomo.track(eventWithCategory: .swipeActions, name: action.matomoName)
            Task {
                await tryOrDisplayError {
                    try await viewModel.handleSwipeAction(action, thread: thread)
                }
            }
        } label: {
            Label { Text(action.title) } icon: { action.icon(from: thread) }
                .labelStyle(.iconOnly)
        }
        .tint(action.swipeTint)
    }
}

struct ThreadListSwipeActions: ViewModifier {
    let thread: Thread
    let viewModel: ThreadListViewModel
    let multipleSelectionViewModel: ThreadListMultipleSelectionViewModel

    @AppStorage(UserDefaults.shared.key(.swipeFullLeading)) private var swipeFullLeading = DefaultPreferences.swipeFullLeading
    @AppStorage(UserDefaults.shared.key(.swipeLeading)) private var swipeLeading = DefaultPreferences.swipeLeading

    @AppStorage(UserDefaults.shared.key(.swipeFullTrailing)) private var swipeFullTrailing = DefaultPreferences.swipeFullTrailing
    @AppStorage(UserDefaults.shared.key(.swipeTrailing)) private var swipeTrailing = DefaultPreferences.swipeTrailing

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
        }
    }

    @MainActor @ViewBuilder
    private func edgeActions(_ actions: [SwipeAction]) -> some View {
        if !multipleSelectionViewModel.isEnabled {
            ForEach(actions.filter { $0 != .none }, id: \.rawValue) { action in
                SwipeActionView(thread: thread, viewModel: viewModel, action: action)
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
        SwipeActionView(thread: PreviewHelper.sampleThread,
                        viewModel: ThreadListViewModel(mailboxManager: PreviewHelper.sampleMailboxManager,
                                                       folder: PreviewHelper.sampleFolder,
                                                       bottomSheet: ThreadBottomSheet(),
                                                       moveSheet: MoveSheet()),
                        action: .delete)
    }
}
