/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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
    func compactToolbar(frozenThread: Thread) -> some View {
        modifier(CompactToolbarModifier(frozenThread: frozenThread))
    }
}

struct CompactToolbarModifier: ViewModifier {
    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var actionsManager: ActionsManager
    @EnvironmentObject private var actionsProvider: ActionsProvider

    @State private var replyOrReplyAllMessage: Message?

    @ModalState private var messagesToMove: [Message]?
    @ModalState private var destructiveAlert: DestructiveActionAlertState?

    private let isFlagged: Bool
    private let frozenFolder: Folder?
    private let frozenMessages: [Message]

    private var toolbarActions: [Action] {
        return actionsProvider.actionsFor(origin: origin, messages: frozenMessages)
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

    private var origin: ActionOrigin {
        .toolbarCompact(
            originFolder: frozenFolder,
            nearestDestructiveAlert: $destructiveAlert,
            nearestMessagesToMoveSheet: $messagesToMove
        )
    }

    init(frozenThread: Thread) {
        isFlagged = frozenThread.flagged
        frozenFolder = frozenThread.folder
        frozenMessages = frozenThread.messages.toArray()
    }

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    moreButton
                }
            }
            .toolbarSpacer(placement: .bottomBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: didTapFlag) {
                        Label(isFlagged ? MailResourcesStrings.Localizable.actionUnstar : MailResourcesStrings.Localizable
                            .actionStar,
                            asset: isFlagged ? MailResourcesAsset.starFull.swiftUIImage : MailResourcesAsset.star
                                .swiftUIImage)
                    }
                    .tint(flaggedTint)
                    .accessibilityLabel(isFlagged ? MailResourcesStrings.Localizable.actionUnstar : MailResourcesStrings
                        .Localizable.actionStar)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    ForEach(toolbarActions) { action in
                        Button {
                            didTap(action: action)
                        } label: {
                            Label(action.title, asset: action.icon)
                        }
                        .disabled(!canPerformAction(action))
                        .modifier(BottomToolbarSnackBarAvoider())
                        if action != toolbarActions.last || showMoreButton {
                            LegacyToolbarSpacer()
                        }
                    }
                }
            }
            .mailCustomAlert(item: $destructiveAlert) { item in
                DestructiveActionAlertView(destructiveAlert: item)
            }
            .sheet(item: $messagesToMove) { messages in
                MoveEmailView(
                    mailboxManager: mailboxManager,
                    movedMessages: messages,
                    originFolder: frozenFolder
                )
                .sheetViewStyle()
            }
            .adaptivePanel(item: $replyOrReplyAllMessage, popoverArrowEdge: .bottom) { message in
                ReplyActionsView(message: message)
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
                    origin: .toolbarCompact(originFolder: frozenFolder)
                )
            }
        }
    }

    private func didTap(action: Action) {
        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .threadActions, name: action.matomoName)

        if action == .reply,
           let message = frozenMessages.lastMessageToExecuteAction(
               currentMailboxEmail: mailboxManager.mailbox.email,
               featureAvailableProvider: mailboxManager.featureAvailableProvider
           ),
           message.canReplyAll(currentMailboxEmail: mailboxManager.mailbox.email) {
            replyOrReplyAllMessage = message
            return
        }

        Task {
            await tryOrDisplayError {
                try await actionsManager.performAction(
                    target: frozenMessages,
                    action: action,
                    origin: origin
                )
            }
        }
    }

    private func canPerformAction(_ action: Action) -> Bool {
        switch action {
        case .reply, .forward, .replyAll:
            return actionsManager.canSendEmails
        default:
            return true
        }
    }
}
