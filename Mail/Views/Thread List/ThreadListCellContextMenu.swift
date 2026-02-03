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
import MailResources
import SwiftModalPresentation
import SwiftUI

extension View {
    func actionsContextMenu(thread: Thread,
                            originFolder: Folder,
                            multipleSelectionViewModel: MultipleSelectionViewModel) -> some View {
        modifier(ThreadListCellContextMenu(
            thread: thread,
            originFolder: originFolder,
            multipleSelectionViewModel: multipleSelectionViewModel
        ))
    }
}

struct ThreadListCellContextMenu: ViewModifier {
    @Environment(\.currentUser) private var currentUser

    @EnvironmentObject private var actionsManager: ActionsManager
    @EnvironmentObject private var mailboxManager: MailboxManager

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
    let originFolder: Folder?
    let multipleSelectionViewModel: MultipleSelectionViewModel

    private var origin: ActionOrigin {
        .floatingPanel(
            source: .threadList,
            originFolder: originFolder?.freezeIfNeeded(),
            nearestDestructiveAlert: $destructiveAlert,
            nearestMessagesToMoveSheet: $messagesToMove,
            nearestBlockSenderAlert: $blockSenderAlert,
            nearestBlockSendersList: $blockSendersList,
            nearestReportedForPhishingMessagesAlert: $reportedForPhishingMessages,
            nearestReportedForDisplayProblemMessageAlert: $reportedForDisplayProblemMessage,
            nearestShareMailLinkPanel: $shareMailLink,
            nearestMessagesToSnooze: $messagesToSnooze,
            messagesToDownload: $messagesToDownload
        )
    }

    private var actions: (quickActions: [Action], listActions: [Action]) {
        let actions = Action.actionsForMessages(
            thread.messages.toArray(),
            origin: origin,
            userIsStaff: currentUser.value.isStaff ?? false,
            userEmail: currentUser.value.email
        )

        return actions
    }

    private var initialSnoozedDate: Date? {
        guard let messagesToSnooze,
              let initialDate = messagesToSnooze.first?.snoozeEndDate,
              messagesToSnooze.allSatisfy({ $0.isSnoozed && $0.snoozeEndDate == initialDate })
        else { return nil }

        return initialDate
    }

    func body(content: Content) -> some View {
        content
            .contextMenu {
                let computedActions = actions // Capture actions to avoid re-computation

                ControlGroup {
                    ForEach(computedActions.quickActions) { action in
                        ContextMenuActionButtonView(action: action, role: isDestructiveAction(action), onClick: performAction)
                    }
                }
                .controlGroupStyle(.compactMenu)

                ContextMenuActionButtonView(action: .activeMultiselect, role: nil) { _ in
                    multipleSelectionViewModel.toggleMultipleSelection(of: thread, withImpact: false)
                }

                ForEach(computedActions.listActions) { action in
                    ContextMenuActionButtonView(action: action, role: isDestructiveAction(action), onClick: performAction)
                }
            }
            .sheet(item: $messagesToMove) { messages in
                MoveEmailView(
                    mailboxManager: mailboxManager,
                    movedMessages: messages,
                    originFolder: originFolder
                )
                .sheetViewStyle()
            }
            .mailFloatingPanel(item: $blockSendersList,
                               title: MailResourcesStrings.Localizable.blockAnExpeditorTitle) { blockSenderState in
                BlockSenderView(recipientsToMessage: blockSenderState.recipientsToMessage, origin: origin)
            }
            .mailCustomAlert(item: $blockSenderAlert) { blockSenderState in
                ConfirmationBlockRecipientView(
                    recipients: blockSenderState.recipients,
                    reportedMessages: blockSenderState.messages,
                    origin: origin
                )
            }
            .mailCustomAlert(
                item: $reportedForDisplayProblemMessage
            ) { message in
                ReportDisplayProblemView(message: message)
            }
            .mailCustomAlert(
                item: $reportedForPhishingMessages
            ) { messages in
                ReportPhishingView(
                    messagesWithDuplicates: messages,
                    distinctMessageCount: messages.count
                )
            }
            .mailCustomAlert(item: $destructiveAlert) { item in
                DestructiveActionAlertView(destructiveAlert: item)
            }
            .mailCustomAlert(item: $messagesToDownload) { messages in
                ConfirmationSaveThreadInKdrive(targetMessages: messages)
            }
            .sheet(item: $shareMailLink) { shareMailLinkResult in
                ActivityView(activityItems: [shareMailLinkResult.url])
                    .ignoresSafeArea(edges: [.bottom])
                    .presentationDetents([.medium, .large])
            }
            .snoozedFloatingPanel(
                messages: messagesToSnooze,
                initialDate: initialSnoozedDate,
                folder: originFolder?.freezeIfNeeded()
            )
    }

    private func performAction(for action: Action) {
        Task {
            await tryOrDisplayError {
                try await actionsManager.performAction(
                    target: thread.messages.toArray(),
                    action: action,
                    origin: origin
                )
            }
        }
    }

    private func isDestructiveAction(_ action: Action) -> ButtonRole? {
        guard action != .archive else {
            return nil
        }
        return action.isDestructive(for: thread) ? .destructive : nil
    }
}
