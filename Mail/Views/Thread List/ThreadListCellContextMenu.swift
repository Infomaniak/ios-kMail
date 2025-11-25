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
import InfomaniakDI
import MailCore
import SwiftModalPresentation
import SwiftUI

extension View {
    func actionsContextMenu(thread: Thread, toggleMultipleSelection: @escaping (Bool) -> Void) -> some View {
        modifier(ThreadListCellContextMenu(thread: thread, toggleMultipleSelection: toggleMultipleSelection))
    }
}

struct ThreadListCellContextMenu: ViewModifier {
    @Environment(\.currentUser) private var currentUser

    @EnvironmentObject private var actionsManager: ActionsManager
    @EnvironmentObject private var mailboxManager: MailboxManager

    @ModalState private var messagesToMove: [Message]?

    let thread: Thread
    let toggleMultipleSelection: (Bool) -> Void

    private var actions: (quickActions: [Action], listActions: [Action]) {
        return Action.actionsForMessages(
            messagesToMove ?? [],
            origin: .floatingPanel(source: .threadList),
            userIsStaff: currentUser.value.isStaff ?? false,
            userEmail: currentUser.value.email
        )
    }

    func body(content: Content) -> some View {
        content
            .contextMenu {
                if #available(iOS 16.4, *) {
                    ControlGroup {
                        ForEach(actions.quickActions) { action in
                            actionButton(for: action)
                        }
                    }
                    .controlGroupStyle(.compactMenu)
                }

                actionButton(for: .activeMultiselect)

                ForEach(actions.listActions) { action in
                    actionButton(for: action)
                }
            }
            .sheet(item: $messagesToMove) { messages in
                MoveEmailView(mailboxManager: mailboxManager, movedMessages: messages, originFolder: thread.folder)
                    .sheetViewStyle()
            }
    }

    private func isDestructiveAction(_ action: Action) -> ButtonRole? {
        guard action != .archive else {
            return nil
        }
        return action.isDestructive(for: thread) ? .destructive : nil
    }

    private func actionButton(for action: Action) -> some View {
        Button(role: isDestructiveAction(action)) {
            guard action != .activeMultiselect else {
                toggleMultipleSelection(false)
                return
            }
            Task {
                try await actionsManager.performAction(
                    target: thread.messages.toArray(),
                    action: action,
                    origin: .swipe(originFolder: thread.folder, nearestMessagesToMoveSheet: $messagesToMove)
                )
            }
        } label: {
            Label {
                Text(action.title)
            } icon: {
                action.icon
                    .resizable()
                    .scaledToFit()
            }
        }
    }
}
