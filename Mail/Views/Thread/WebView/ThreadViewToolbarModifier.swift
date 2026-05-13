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
    private static let replyActions: [Action] = [.reply, .forward, .replyAll]
    private static let moveStandardActions: [Action] = [.snooze, .archive, .openMovePanel, .delete]
    private static let moveArchiveActions: [Action] = [.snooze, .moveToInbox, .openMovePanel, .delete]
    private static let reportActions: [Action] = [.block, .spam, .phishing]
    private static let otherNoReadActions: [Action] = [.markAsRead, .shareMailLink, .saveThreadInkDrive]
    private static let otherReadActions: [Action] = [.markAsUnread, .shareMailLink, .saveThreadInkDrive]

    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var actionsManager: ActionsManager

    @Environment(\.isCompactWindow) private var isCompactWindow

    @ModalState private var reportedForDisplayProblemMessage: Message?
    @ModalState private var reportedForPhishingMessages: [Message]?
    @ModalState private var blockSenderAlert: BlockRecipientAlertState?
    @ModalState private var blockSendersList: BlockRecipientState?
    @ModalState private var messagesToMove: [Message]?
    @ModalState private var destructiveAlert: DestructiveActionAlertState?
    @ModalState private var shareMailLink: ShareMailLinkResult?
    @ModalState private var messagesToSnooze: [Message]?
    @ModalState private var messagesToDownload: [Message]?

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

    private var toolbarActionsForOther: [Action] {
        frozenMessages.contains(where: \.seen) ? Self.otherReadActions : Self.otherNoReadActions
    }

    private var toolbarActionsForMove: [Action] {
        frozenFolder?.role == .archive ? Self.moveArchiveActions : Self.moveStandardActions
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

    private var initialSnoozedDate: Date? {
        guard let messagesToSnooze,
              let initialDate = messagesToSnooze.first?.snoozeEndDate,
              messagesToSnooze.allSatisfy({ $0.isSnoozed && $0.snoozeEndDate == initialDate })
        else { return nil }

        return initialDate
    }

    private var origin: ActionOrigin {
        .toolbar(
            originFolder: frozenFolder,
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

    init(frozenThread: Thread) {
        self.frozenThread = frozenThread

        isFlagged = frozenThread.flagged
        frozenFolder = frozenThread.folder
        frozenMessages = frozenThread.messages.toArray()
    }

    func body(content: Content) -> some View {
        let itemPlacementTrailing: ToolbarItemPlacement = isCompactWindow ? .bottomBar : .navigationBarTrailing
        let itemPlacementLeading: ToolbarItemPlacement = isCompactWindow ? .bottomBar : .navigationBarLeading

        content
            .toolbar {
                ToolbarItemGroup(placement: itemPlacementTrailing) {
                    if showMoreButton {
                        if isCompactWindow {
                            moreButton
                        } else {
                            ForEach(toolbarActionsForOther) { action in
                                Button {
                                    didTap(action: action)
                                } label: {
                                    Label(action.title, asset: action.icon)
                                }
                            }
                        }
                    }
                }
            }

            .toolbarSpacer(placement: itemPlacementTrailing)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: didTapFlag) {
                        (isFlagged ? MailResourcesAsset.starFull : MailResourcesAsset.star)
                            .swiftUIImage
                    }
                    .tint(flaggedTint)
                    .accessibilityLabel(isFlagged ? MailResourcesStrings.Localizable.actionUnstar : MailResourcesStrings
                        .Localizable.actionStar)
                }
            }
            .toolbar {
                if !isCompactWindow {
                    ToolbarItemGroup(placement: itemPlacementLeading) {
                        ForEach(ThreadViewToolbarModifier.replyActions) { action in
                            Button {
                                didTap(action: action)
                            } label: {
                                Label(action.title, asset: action.icon)
                            }
                        }
                    }

                    if #available(iOS 26.0, *) {
                        ToolbarSpacer(.fixed, placement: .topBarLeading)
                    }

                    ToolbarItemGroup(placement: itemPlacementLeading) {
                        ForEach(toolbarActionsForMove) { action in
                            Button {
                                didTap(action: action)
                            } label: {
                                Label(action.title, asset: action.icon)
                            }
                        }
                    }

                    if #available(iOS 26.0, *) {
                        ToolbarSpacer(.fixed, placement: .topBarTrailing)
                    }

                    ToolbarItemGroup(placement: itemPlacementTrailing) {
                        ForEach(ThreadViewToolbarModifier.reportActions) { action in
                            Button {
                                didTap(action: action)
                            } label: {
                                Label(action.title, asset: action.icon)
                            }
                        }
                    }

                    if #available(iOS 26.0, *) {
                        ToolbarSpacer(.fixed, placement: .topBarTrailing)
                    }

                } else {
                    ToolbarItemGroup(placement: itemPlacementLeading) {
                        ForEach(toolbarActions) { action in
                            Button {
                                didTap(action: action)
                            } label: {
                                Label(action.title, asset: action.icon)
                            }
                            if action != toolbarActions.last || showMoreButton {
                                LegacyToolbarSpacer()
                            }
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
                    originFolder: frozenFolder,
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
                folder: frozenFolder?.freezeIfNeeded()
            )
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
        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .threadActions, name: action.matomoName)

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
        case .reply, .forward:
            return actionsManager.canSendEmails
        default:
            return true
        }
    }
}
