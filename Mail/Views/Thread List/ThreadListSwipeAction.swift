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

private struct SwipeActionView: View {
    let thread: Thread
    let viewModel: ThreadListViewModel
    let action: SwipeAction

    private var icon: Image? {
        if action == .readUnread {
            return Image(resource: thread.unseenMessages == 0 ? MailResourcesAsset.envelope : MailResourcesAsset.envelopeOpen)
        }
        return action.swipeIcon
    }

    var body: some View {
        Button {
            Task {
                await tryOrDisplayError {
                    try await viewModel.hanldeSwipeAction(action, thread: thread)
                }
            }
        } label: {
            Label { Text(action.title) } icon: { icon }
                .labelStyle(.iconOnly)
        }
        .tint(action.swipeTint)
    }
}

struct ThreadListSwipeActions: ViewModifier {
    let thread: Thread
    let viewModel: ThreadListViewModel

    @AppStorage(UserDefaults.shared.key(.swipeLongRight)) private var swipeLongRight = Constants.defaultSwipeLongRight
    @AppStorage(UserDefaults.shared.key(.swipeShortRight)) private var swipeShortRight = Constants.defaultSwipeShortRight

    @AppStorage(UserDefaults.shared.key(.swipeLongLeft)) private var swipeLongLeft = Constants.defaultSwipeLongLeft
    @AppStorage(UserDefaults.shared.key(.swipeShortLeft)) private var swipeShortLeft = Constants.defaultSwipeShortLeft

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading) {
                edgeActions([swipeLongRight, swipeShortRight])
            }
            .swipeActions(edge: .trailing) {
                edgeActions([swipeLongLeft, swipeShortLeft])
            }
    }

    private func edgeActions(_ actions: [SwipeAction]) -> some View {
        ForEach(actions.filter { $0 != .none }, id: \.rawValue) { action in
            SwipeActionView(thread: thread, viewModel: viewModel, action: action)
        }
    }
}

extension View {
    func swipeActions(thread: Thread, viewModel: ThreadListViewModel) -> some View {
        modifier(ThreadListSwipeActions(thread: thread, viewModel: viewModel))
    }
}

struct ThreadListSwipeAction_Previews: PreviewProvider {
    static var previews: some View {
        SwipeActionView(thread: PreviewHelper.sampleThread,
                        viewModel: ThreadListViewModel(mailboxManager: PreviewHelper.sampleMailboxManager,
                                                       folder: nil,
                                                       bottomSheet: ThreadBottomSheet()),
                        action: .delete)
    }
}
