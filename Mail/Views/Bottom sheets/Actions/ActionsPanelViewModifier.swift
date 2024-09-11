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
        completionHandler: ((Action) -> Void)? = nil
    ) -> some View {
        return modifier(ActionsPanelViewModifier(
            messages: messages,
            originFolder: originFolder,
            panelSource: panelSource,
            completionHandler: completionHandler
        ))
    }
}

struct ActionsPanelViewModifier: ViewModifier {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @ModalState private var reportForJunkMessages: [Message]?
    @ModalState private var reportedForDisplayProblemMessage: Message?
    @ModalState private var reportedForPhishingMessage: Message?
    @ModalState private var blockSenderAlert: BlockRecipientAlertState?
    @ModalState private var blockSendersList: BlockRecipientState?
    @ModalState private var messagesToMove: [Message]?
    @ModalState private var flushAlert: FlushAlertState?
    @ModalState private var shareMailLink: ShareMailLinkResult?

    @Binding var messages: [Message]?
    let originFolder: Folder?
    let panelSource: ActionOrigin.FloatingPanelSource

    var completionHandler: ((Action) -> Void)?

    private var origin: ActionOrigin {
        .floatingPanel(
            source: panelSource,
            originFolder: originFolder?.freezeIfNeeded(),
            nearestFlushAlert: $flushAlert,
            nearestMessagesToMoveSheet: $messagesToMove,
            nearestBlockSenderAlert: $blockSenderAlert,
            nearestBlockSendersList: $blockSendersList,
            nearestReportJunkMessageActionsPanel: $reportForJunkMessages,
            nearestReportedForPhishingMessageAlert: $reportedForPhishingMessage,
            nearestReportedForDisplayProblemMessageAlert: $reportedForDisplayProblemMessage,
            nearestShareMailLinkPanel: $shareMailLink
        )
    }

    func body(content: Content) -> some View {
        content.adaptivePanel(item: $messages) { messages in
            ActionsView(mailboxManager: mailboxManager, target: messages, origin: origin, completionHandler: completionHandler)
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
        .floatingPanel(item: $reportForJunkMessages) { reportForJunkMessages in
            ReportJunkView(reportedMessages: reportForJunkMessages, origin: origin)
        }
        .floatingPanel(item: $blockSendersList,
                       title: MailResourcesStrings.Localizable.blockAnExpeditorTitle) { blockSenderState in
            BlockSenderView(recipientsToMessage: blockSenderState.recipientsToMessage, origin: origin)
        }
        .customAlert(item: $blockSenderAlert) { blockSenderState in
            ConfirmationBlockRecipientView(
                recipient: blockSenderState.recipient,
                reportedMessage: blockSenderState.message,
                origin: origin
            )
        }
        .customAlert(item: $reportedForDisplayProblemMessage) { message in
            ReportDisplayProblemView(message: message)
        }
        .customAlert(item: $reportedForPhishingMessage) { message in
            ReportPhishingView(message: message)
        }
        .customAlert(item: $flushAlert) { item in
            FlushFolderAlertView(flushAlert: item, folder: originFolder)
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
    }
}
