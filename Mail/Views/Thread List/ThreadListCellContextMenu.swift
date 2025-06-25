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

    @ModalState private var reportForJunkMessages: [Message]?
    @ModalState private var reportedForDisplayProblemMessage: Message?
    @ModalState private var reportedForPhishingMessages: [Message]?
    @ModalState private var blockSenderAlert: BlockRecipientAlertState?
    @ModalState private var blockSendersList: BlockRecipientState?
    @ModalState private var messagesToMove: [Message]?
    @ModalState private var destructiveAlert: DestructiveActionAlertState?
    @ModalState private var shareMailLink: ShareMailLinkResult?
    @ModalState private var messagesToSnooze: [Message]?
    @ModalState private var messagesToDownload: [Message]?

    let thread: Thread
    let toggleMultipleSelection: (Bool) -> Void

    private var actions: Action.Lists {
        Action.actionsForMessages(
            thread.messages.toArray(),
            origin: origin,
            userIsStaff: currentUser.value.isStaff ?? false,
            userEmail: currentUser.value.email
        )
    }

    private var origin: ActionOrigin {
        .floatingPanel(
            source: .contextMenu,
            originFolder: thread.folder?.freezeIfNeeded(),
            nearestDestructiveAlert: $destructiveAlert,
            nearestMessagesToMoveSheet: $messagesToMove,
            nearestBlockSenderAlert: $blockSenderAlert,
            nearestBlockSendersList: $blockSendersList,
            nearestReportJunkMessagesActionsPanel: $reportForJunkMessages,
            nearestReportedForPhishingMessagesAlert: $reportedForPhishingMessages,
            nearestReportedForDisplayProblemMessageAlert: $reportedForDisplayProblemMessage,
            nearestShareMailLinkPanel: $shareMailLink,
            nearestMessagesToSnooze: $messagesToSnooze,
            messagesToDownload: $messagesToDownload
        )
    }

    func body(content: Content) -> some View {
        content
            .contextMenu {
                ControlGroup {
                    ActionButtonForEach(
                        actions: actions.bottomBarActions,
                        messages: thread.messages.toArray(),
                        thread: thread,
                        origin: origin,
                        toggleMultipleSelection: toggleMultipleSelection
                    )
                }
                .modifier(controlGroupStyleCompactStyle())

                ActionButtonForEach(
                    actions: actions.listActions,
                    messages: thread.messages.toArray(),
                    thread: thread,
                    origin: origin,
                    toggleMultipleSelection: toggleMultipleSelection
                )
            }
            .actionAlertsView(
                reportForJunkMessages: $reportForJunkMessages,
                reportedForDisplayProblemMessage: $reportedForDisplayProblemMessage,
                reportedForPhishingMessages: $reportedForPhishingMessages,
                blockSenderAlert: $blockSenderAlert,
                blockSendersList: $blockSendersList,
                messagesToMove: $messagesToMove,
                destructiveAlert: $destructiveAlert,
                shareMailLink: $shareMailLink,
                messagesToSnooze: $messagesToSnooze,
                messagesToDownload: $messagesToDownload,
                originFolder: thread.folder,
                origin: origin
            )
    }
}

struct controlGroupStyleCompactStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content
                .controlGroupStyle(.compactMenu)
        } else {
            content
        }
    }
}
