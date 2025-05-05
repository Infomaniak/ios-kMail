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

import Foundation
import MailCore
import MailResources
import SwiftModalPresentation
import SwiftUI

struct ActionAlertsViewModifier: ViewModifier {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @Binding var reportForJunkMessages: [Message]?
    @Binding var reportedForDisplayProblemMessage: Message?
    @Binding var reportedForPhishingMessages: [Message]?
    @Binding var blockSenderAlert: BlockRecipientAlertState?
    @Binding var blockSendersList: BlockRecipientState?
    @Binding var messagesToMove: [Message]?
    @Binding var destructiveAlert: DestructiveActionAlertState?
    @Binding var shareMailLink: ShareMailLinkResult?
    @Binding var messagesToSnooze: [Message]?
    @Binding var messagesToDownload: [Message]?

    let originFolder: Folder?
    let origin: ActionOrigin
    var completionHandler: ((Action) -> Void)?

    private var initialSnoozedDate: Date? {
        guard let messagesToSnooze,
              let initialDate = messagesToSnooze.first?.snoozeEndDate,
              messagesToSnooze.allSatisfy({ $0.isSnoozed && $0.snoozeEndDate == initialDate })
        else { return nil }

        return initialDate
    }

    func body(content: Content) -> some View {
        content
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
                ReportJunkView(reportedMessages: reportForJunkMessages, origin: origin, completionHandler: completionHandler)
            }
            .floatingPanel(item: $blockSendersList,
                           title: MailResourcesStrings.Localizable.blockAnExpeditorTitle) { blockSenderState in
                BlockSenderView(recipientsToMessage: blockSenderState.recipientsToMessage, origin: origin)
            }
            .customAlert(item: $blockSenderAlert) { blockSenderState in
                ConfirmationBlockRecipientView(
                    recipients: blockSenderState.recipients,
                    reportedMessages: blockSenderState.messages,
                    origin: origin
                )
            }
            .customAlert(item: $reportedForDisplayProblemMessage) { message in
                ReportDisplayProblemView(message: message)
            }
            .customAlert(item: $reportedForPhishingMessages) { messages in
                ReportPhishingView(
                    messagesWithDuplicates: messages,
                    distinctMessageCount: messages.count,
                    completionHandler: completionHandler
                )
            }
            .customAlert(item: $destructiveAlert) { item in
                DestructiveActionAlertView(destructiveAlert: item)
            }
            .customAlert(item: $messagesToDownload) { messages in
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
                folder: originFolder?.freezeIfNeeded()
            ) { completionHandler?($0) }
    }
}
