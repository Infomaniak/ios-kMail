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

import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftModalPresentation
import SwiftUI

extension View {
    func threadViewToolbar(isFlagged: Bool, frozenFolder: Folder?, frozenMessages: [Message]) -> some View {
        modifier(ThreadViewToolbarModifier(isFlagged: isFlagged, frozenFolder: frozenFolder, frozenMessages: frozenMessages))
    }
}

struct ThreadViewToolbarModifier: ViewModifier {
    private static let standardActions: [Action] = [.reply, .forward, .archive, .delete]
    private static let archiveActions: [Action] = [.reply, .forward, .openMovePanel, .delete]

    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var actionsManager: ActionsManager

    @State private var replyOrReplyAllMessage: Message?
    @State private var messagesToMove: [Message]?

    @ModalState private var nearestFlushAlert: FlushAlertState?

    let isFlagged: Bool
    let frozenFolder: Folder?
    let frozenMessages: [Message]

    private var toolbarActions: [Action] {
        frozenFolder?.role == .archive ? Self.archiveActions : Self.standardActions
    }

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: didTapFlag) {
                        (isFlagged ? MailResourcesAsset.starFull : MailResourcesAsset.star)
                            .swiftUIImage
                            .foregroundStyle(isFlagged ? MailResourcesAsset.yellowColor.swiftUIColor : .accentColor)
                    }
                }
            }
            .bottomBar {
                ForEach(toolbarActions) { action in
                    if action == .reply {
                        ToolbarButton(text: action.title, icon: action.icon) {
                            didTap(action: action)
                        }
                        .adaptivePanel(item: $replyOrReplyAllMessage) { message in
                            ReplyActionsView(message: message)
                        }
                    } else {
                        ToolbarButton(text: action.title, icon: action.icon) {
                            didTap(action: action)
                        }
                        .sheet(item: $messagesToMove) { messages in
                            MoveEmailView(mailboxManager: mailboxManager, movedMessages: messages, originFolder: frozenFolder)
                                .sheetViewStyle()
                        }
                    }
                }
                ActionsPanelButton(messages: frozenMessages, originFolder: frozenFolder, panelSource: .messageList) {
                    ToolbarButtonLabel(text: MailResourcesStrings.Localizable.buttonMore,
                                       icon: MailResourcesAsset.plusActions.swiftUIImage)
                }
            }
            .customAlert(item: $nearestFlushAlert) { item in
                FlushFolderAlertView(flushAlert: item)
            }
    }

    private func didTapFlag() {
        Task {
            await tryOrDisplayError {
                try await actionsManager.performAction(
                    target: frozenMessages,
                    action: isFlagged ? .unstar : .star,
                    origin: .toolbar(originFolder: frozenFolder)
                )
            }
        }
    }

    private func didTap(action: Action) {
        matomo.track(eventWithCategory: .threadActions, name: action.matomoName)

        if action == .reply,
           let message = frozenMessages.lastMessageToExecuteAction(currentMailboxEmail: mailboxManager.mailbox.email),
           message.canReplyAll(currentMailboxEmail: mailboxManager.mailbox.email) {
            replyOrReplyAllMessage = message
            return
        }

        if action == .openMovePanel {
            messagesToMove = frozenMessages
        }

        Task {
            await tryOrDisplayError {
                try await actionsManager.performAction(
                    target: frozenMessages,
                    action: action,
                    origin: .toolbar(originFolder: frozenFolder, nearestFlushAlert: $nearestFlushAlert)
                )
            }
        }
    }
}
