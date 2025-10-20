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
    func threadViewToolbar(frozenThread: Thread) -> some View {
        modifier(ThreadViewToolbarModifier(frozenThread: frozenThread))
    }
}

struct ThreadViewToolbarModifier: ViewModifier {
    private static let standardActions: [Action] = [.reply, .forward, .archive, .delete]
    private static let archiveActions: [Action] = [.reply, .forward, .openMovePanel, .delete]
    private static let scheduleActions: [Action] = [.delete]

    @LazyInjectService private var matomo: MatomoUtils

    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var actionsManager: ActionsManager

    @State private var replyOrReplyAllMessage: Message?
    @State private var messagesToMove: [Message]?

    @ModalState private var destructiveAlert: DestructiveActionAlertState?

    private let frozenThread: Thread

    private let isFlagged: Bool
    private let frozenFolder: Folder?
    private let frozenMessages: [Message]

    private var toolbarActions: [Action] {
        if frozenThread.containsOnlyScheduledDrafts {
            return Self.scheduleActions
        } else if frozenFolder?.role == .archive {
            return Self.archiveActions
        } else {
            return Self.standardActions
        }
    }

    private var showMoreButton: Bool {
        return frozenFolder?.role != .scheduledDrafts
    }

    private var flaggedTint: Color {
        if #available(iOS 26.0, *) {
            return isFlagged ? MailResourcesAsset.yellowColor.swiftUIColor : .primary
        } else {
            return isFlagged ? MailResourcesAsset.yellowColor.swiftUIColor : .accentColor
        }
    }

    init(frozenThread: Thread) {
        self.frozenThread = frozenThread

        isFlagged = frozenThread.flagged
        frozenFolder = frozenThread.folder
        frozenMessages = frozenThread.messages.toArray()
    }

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: didTapFlag) {
                        (isFlagged ? MailResourcesAsset.starFull : MailResourcesAsset.star)
                            .swiftUIImage
                    }
                    .tint(flaggedTint)
                }
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    if #available(iOS 16.0, *), showMoreButton {
                        moreButton
                    }
                }
            }
            .toolbarSpacer(placement: .bottomBar)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    ForEach(toolbarActions) { action in
                        if action == .reply {
                            Button {
                                didTap(action: action)
                            } label: {
                                Label(action.title, asset: action.icon)
                            }
                            .adaptivePanel(item: $replyOrReplyAllMessage, popoverArrowEdge: .bottom) { message in
                                ReplyActionsView(message: message)
                            }
                        } else {
                            Button {
                                didTap(action: action)
                            } label: {
                                Label(action.title, asset: action.icon)
                            }
                            .sheet(item: $messagesToMove) { messages in
                                MoveEmailView(mailboxManager: mailboxManager, movedMessages: messages, originFolder: frozenFolder)
                                    .sheetViewStyle()
                            }
                            .modifier(BottomToolbarSnackBarAvoider())
                        }

                        if action != toolbarActions.last || showMoreButton {
                            LegacyToolbarSpacer()
                        }
                    }

                    if #unavailable(iOS 16.0), showMoreButton {
                        moreButton
                    }
                }
            }
            .mailCustomAlert(item: $destructiveAlert) { item in
                DestructiveActionAlertView(destructiveAlert: item)
            }
    }

    private var moreButton: some View {
        ActionsPanelButton(
            messages: frozenMessages,
            originFolder: frozenFolder,
            panelSource: .messageList,
            popoverArrowEdge: .bottom
        ) {
            Label(MailResourcesStrings.Localizable.buttonMore, asset: MailResourcesAsset.plusActions.swiftUIImage)
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
                    origin: .toolbar(originFolder: frozenFolder, nearestDestructiveAlert: $destructiveAlert)
                )
            }
        }
    }
}
