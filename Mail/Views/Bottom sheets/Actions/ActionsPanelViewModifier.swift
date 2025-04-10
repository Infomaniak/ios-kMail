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
        popoverArrowEdge: Edge,
        completionHandler: ((Action) -> Void)? = nil
    ) -> some View {
        return modifier(ActionsPanelViewModifier(
            messages: messages,
            originFolder: originFolder,
            panelSource: panelSource,
            popoverArrowEdge: popoverArrowEdge,
            completionHandler: completionHandler
        ))
    }
}

struct ActionsPanelViewModifier: ViewModifier {
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

    @Binding var messages: [Message]?
    let originFolder: Folder?
    let panelSource: ActionOrigin.FloatingPanelSource
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
            nearestReportJunkMessagesActionsPanel: $reportForJunkMessages,
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
        content.adaptivePanel(item: $messages, popoverArrowEdge: popoverArrowEdge) { messages in
            ActionsView(
                user: currentUser.value,
                target: messages,
                origin: origin,
                completionHandler: completionHandler
            )
        }
        .modifier(ActionAlertsViewModifier(
            reportForJunkMessages: $reportForJunkMessages,
            reportedForDisplayProblemMessage: $reportedForDisplayProblemMessage,
            reportedForPhishingMessages: $reportedForPhishingMessages,
            blockSenderAlert: $blockSenderAlert,
            blockSendersList: $blockSendersList,
            messagesToMove: $messagesToMove,
            flushAlert: $flushAlert,
            shareMailLink: $shareMailLink,
            messagesToSnooze: $messagesToSnooze,
            messagesToDownload: $messagesToDownload,
            originFolder: originFolder,
            origin: origin,
            completionHandler: completionHandler
        ))
    }
}
