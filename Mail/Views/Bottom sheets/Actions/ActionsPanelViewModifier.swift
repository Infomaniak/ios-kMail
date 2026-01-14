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

import Foundation
import MailCore
import MailResources
import SwiftModalPresentation
import SwiftUI

extension View {
    func actionsPanel(
        messages: Binding<[Message]?>,
        originFolder: Folder?,
        panelSource: ActionOrigin.FloatingPanelSource,
        isMultipleSelection: Bool = false,
        popoverArrowEdge: Edge,
        completionHandler: ((Action) -> Void)? = nil
    ) -> some View {
        return modifier(ActionsPanelViewModifier(
            messages: messages,
            originFolder: originFolder,
            panelSource: panelSource,
            isMultipleSelection: isMultipleSelection,
            popoverArrowEdge: popoverArrowEdge,
            completionHandler: completionHandler
        ))
    }
}

struct ActionsPanelViewModifier: ViewModifier {
    @Environment(\.currentUser) private var currentUser

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

    @Binding var messages: [Message]?
    let originFolder: Folder?
    let panelSource: ActionOrigin.FloatingPanelSource
    let isMultipleSelection: Bool
    var popoverArrowEdge: Edge
    var completionHandler: ((Action) -> Void)?

    private var origin: ActionOrigin {
        .floatingPanel(
            source: panelSource,
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

    private var initialSnoozedDate: Date? {
        guard let messagesToSnooze,
              let initialDate = messagesToSnooze.first?.snoozeEndDate,
              messagesToSnooze.allSatisfy({ $0.isSnoozed && $0.snoozeEndDate == initialDate })
        else { return nil }

        return initialDate
    }

    func body(content: Content) -> some View {
        content.adaptivePanel(item: $messages, style: .native, popoverArrowEdge: popoverArrowEdge) { messages in
            ActionsView(
                user: currentUser.value,
                target: messages,
                origin: origin,
                isMultipleSelection: isMultipleSelection,
                completionHandler: completionHandler
            )
        }
        .sheet(item: $messagesToMove) { messages in
            MoveEmailView(
                mailboxManager: mailboxManager,
                movedMessages: messages,
                originFolder: originFolder,
                completion: completionHandler
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
                distinctMessageCount: messages.count,
                completionHandler: completionHandler
            )
        }
        .mailCustomAlert(item: $destructiveAlert) { item in
            DestructiveActionAlertView(destructiveAlert: item)
        }
        .mailCustomAlert(item: $messagesToDownload) { messages in
            ConfirmationSaveThreadInKdrive(targetMessages: messages)
        }
        .sheet(item: $shareMailLink) { shareMailLinkResult in
            if #available(iOS 16.0, *) {
                ActivityView(activityItems: [shareMailLinkResult.url])
                    .ignoresSafeArea(edges: [.bottom])
                    .presentationDetents([.medium, .large])
            } else {
                ActivityView(activityItems: [shareMailLinkResult.url])
                    .ignoresSafeArea(edges: [.bottom])
                    .backport.presentationDetents([.medium, .large])
            }
        }
        .snoozedFloatingPanel(
            messages: messagesToSnooze,
            initialDate: initialSnoozedDate,
            folder: originFolder?.freezeIfNeeded(),
            completionHandler: completionHandler
        )
    }
}
