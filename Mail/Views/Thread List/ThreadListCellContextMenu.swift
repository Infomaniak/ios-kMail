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
    func actionsContextMenu(thread: Thread, toggleMultiSelectionFunction: @escaping (Bool) -> Void) -> some View {
        modifier(ThreadListCellContextMenu(thread: thread, toggleMultiSelectionFunction: toggleMultiSelectionFunction))
    }
}

struct ThreadListCellContextMenu: ViewModifier {
    @EnvironmentObject private var actionsManager: ActionsManager
    @EnvironmentObject private var mailboxManager: MailboxManager

    @ModalState private var messagesToMove: [Message]?

    let thread: Thread
    let toggleMultiSelectionFunction: (Bool) -> Void

    private var actions: [Action] {
        return Action.rightClickActions
    }

    func body(content: Content) -> some View {
        content
            .contextMenu {
                ForEach(actions) { action in
                    Button(role: isDestructiveAction(action)) {
                        if action == .activeMultiselect {
                            toggleMultiSelectionFunction(false)
                        } else {
                            Task {
                                try await actionsManager.performAction(
                                    target: thread.messages.toArray(),
                                    action: action,
                                    origin: .swipe(originFolder: thread.folder, nearestMessagesToMoveSheet: $messagesToMove)
                                )
                            }
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
            .sheet(item: $messagesToMove) { messages in
                MoveEmailView(mailboxManager: mailboxManager, movedMessages: messages, originFolder: thread.folder)
                    .sheetViewStyle()
            }
    }

    private func isDestructiveAction(_ action: Action) -> ButtonRole? {
        guard action == .archive else {
            return action.isDestructive ? .destructive : nil
        }
        return nil
    }
}
