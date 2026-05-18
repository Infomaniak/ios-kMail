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
    func largeToolbar(frozenThread: Thread) -> some View {
        modifier(LargeToolbarModifier(frozenThread: frozenThread))
    }
}

struct LargeToolbarModifier: ViewModifier {
    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var actionsManager: ActionsManager

    @ModalState private var reportedForDisplayProblemMessage: Message?
    @ModalState private var reportedForPhishingMessages: [Message]?
    @ModalState private var blockSenderAlert: BlockRecipientAlertState?
    @ModalState private var blockSendersList: BlockRecipientState?
    @ModalState private var messagesToMove: [Message]?
    @ModalState private var destructiveAlert: DestructiveActionAlertState?
    @ModalState private var shareMailLink: ShareMailLinkResult?
    @ModalState private var messagesToSnooze: [Message]?
    @ModalState private var messagesToDownload: [Message]?

    private let isFlagged: Bool
    private let isRead: Bool
    private let isArchive: Bool

    private let frozenFolder: Folder?
    private let frozenMessages: [Message]

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
        .toolbarLarge(
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
        isFlagged = frozenThread.flagged
        isRead = frozenThread.messages.allSatisfy { $0.seen }
        isArchive = frozenThread.folder?.role == .archive
        frozenFolder = frozenThread.folder
        frozenMessages = frozenThread.messages.toArray()
    }

    func body(content: Content) -> some View {
        content
            .toolbar(id: "thread.largeToolbar") {
                toolbarItemReply()
                toolbarItemMove()
                toolbarItemReport()
                toolbarItemOther()
                toolbarItemGroups()
            }
            .toolbarRole(.editor)
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
            .mailCustomAlert(item: $reportedForDisplayProblemMessage) { message in
                ReportDisplayProblemView(message: message)
            }
            .mailCustomAlert(item: $reportedForPhishingMessages) { messages in
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

    @ToolbarContentBuilder
    private func toolbarItemGroups() -> some CustomizableToolbarContent {
        ToolbarItem(id: "thread.move", placement: .secondaryAction) {
            ControlGroup {
                Button { didTap(action: .snooze) } label: {
                    Label(Action.snooze.title, asset: Action.snooze.icon)
                }

                Button(action: didTapArchive) {
                    Label(
                        isArchive ? MailResourcesStrings.Localizable.actionMoveToInbox : MailResourcesStrings.Localizable
                            .actionArchive,
                        asset: isArchive ? Action.moveToInbox.icon : Action.archive.icon
                    )
                }

                Button { didTap(action: .openMovePanel) } label: {
                    Label(Action.openMovePanel.title, asset: Action.openMovePanel.icon)
                }

                Button { didTap(action: .delete) } label: {
                    Label(Action.delete.title, asset: Action.delete.icon)
                }
            } label: {
                Label(MailResourcesStrings.Localizable.buttonMore, systemImage: "arrow.forward.folder")
            }
        }
        .defaultCustomization(.visible, options: .alwaysAvailable)

        ToolbarItem(id: "thread.report", placement: .secondaryAction) {
            ControlGroup {
                Button { didTap(action: .block) } label: {
                    Label(Action.block.title, asset: Action.block.icon)
                }

                Button { didTap(action: .spam) } label: {
                    Label(Action.spam.title, asset: Action.spam.icon)
                }

                Button { didTap(action: .phishing) } label: {
                    Label(Action.phishing.title, asset: Action.phishing.icon)
                }
            } label: {
                Label(MailResourcesStrings.Localizable.buttonMore, systemImage: "nosign")
            }
        }
        .defaultCustomization(.visible, options: .alwaysAvailable)

        ToolbarItem(id: "thread.other", placement: .secondaryAction) {
            ControlGroup {
                Button(action: didTapRead) {
                    Label(
                        isRead ? MailResourcesStrings.Localizable.actionMarkAsUnread : MailResourcesStrings.Localizable
                            .actionMarkAsRead,
                        asset: isRead ? Action.markAsUnread.icon : Action.markAsRead.icon
                    )
                }

                Button { didTap(action: .shareMailLink) } label: {
                    Label(Action.shareMailLink.title, asset: Action.shareMailLink.icon)
                }

                Button(action: didTapFlag) {
                    Label(isFlagged ? MailResourcesStrings.Localizable.actionUnstar : MailResourcesStrings.Localizable
                        .actionStar,
                        asset: isFlagged ? MailResourcesAsset.starFull.swiftUIImage : MailResourcesAsset.star.swiftUIImage)
                }
                .tint(flaggedTint)
                .accessibilityLabel(isFlagged ? MailResourcesStrings.Localizable.actionUnstar : MailResourcesStrings
                    .Localizable.actionStar)

                Button { didTap(action: .saveThreadInkDrive) } label: {
                    Label(Action.saveThreadInkDrive.title, asset: Action.saveThreadInkDrive.icon)
                }
            } label: {
                Label(MailResourcesStrings.Localizable.buttonMore, asset: MailResourcesAsset.plusActions.swiftUIImage)
            }
        }
        .defaultCustomization(.visible, options: .alwaysAvailable)
    }

    @ToolbarContentBuilder
    private func toolbarItemOther() -> some CustomizableToolbarContent {
        ToolbarItem(id: "thread.other.markAsRead", placement: .secondaryAction) {
            Button(action: didTapRead) {
                Label(
                    isRead ? MailResourcesStrings.Localizable.actionMarkAsUnread : MailResourcesStrings.Localizable
                        .actionMarkAsRead,
                    asset: isRead ? Action.markAsUnread.icon : Action.markAsRead.icon
                )
            }
        }
        .defaultCustomization(.hidden)

        ToolbarItem(id: "thread.other.shareMailLink", placement: .secondaryAction) {
            Button { didTap(action: .shareMailLink) } label: {
                Label(Action.shareMailLink.title, asset: Action.shareMailLink.icon)
            }
        }
        .defaultCustomization(.hidden)

        ToolbarItem(id: "thread.other.star", placement: .secondaryAction) {
            Button(action: didTapFlag) {
                Label(isFlagged ? MailResourcesStrings.Localizable.actionUnstar : MailResourcesStrings.Localizable
                    .actionStar,
                    asset: isFlagged ? MailResourcesAsset.starFull.swiftUIImage : MailResourcesAsset.star.swiftUIImage)
            }
            .tint(flaggedTint)
            .accessibilityLabel(isFlagged ? MailResourcesStrings.Localizable.actionUnstar : MailResourcesStrings
                .Localizable.actionStar)
        }
        .defaultCustomization(.hidden)

        ToolbarItem(id: "thread.other.saveThreadInkDrive", placement: .secondaryAction) {
            Button { didTap(action: .saveThreadInkDrive) } label: {
                Label(Action.saveThreadInkDrive.title, asset: Action.saveThreadInkDrive.icon)
            }
        }
        .defaultCustomization(.hidden)
    }

    @ToolbarContentBuilder
    private func toolbarItemReport() -> some CustomizableToolbarContent {
        ToolbarItem(id: "thread.report.block", placement: .secondaryAction) {
            Button { didTap(action: .block) } label: {
                Label(Action.block.title, asset: Action.block.icon)
            }
        }
        .defaultCustomization(.hidden)

        ToolbarItem(id: "thread.report.spam", placement: .secondaryAction) {
            Button { didTap(action: .spam) } label: {
                Label(Action.spam.title, asset: Action.spam.icon)
            }
        }
        .defaultCustomization(.hidden)

        ToolbarItem(id: "thread.report.phishing", placement: .secondaryAction) {
            Button { didTap(action: .phishing) } label: {
                Label(Action.phishing.title, asset: Action.phishing.icon)
            }
        }
        .defaultCustomization(.hidden)
    }

    @ToolbarContentBuilder
    private func toolbarItemMove() -> some CustomizableToolbarContent {
        ToolbarItem(id: "thread.move.snooze", placement: .secondaryAction) {
            Button { didTap(action: .snooze) } label: {
                Label(Action.snooze.title, asset: Action.snooze.icon)
            }
        }
        .defaultCustomization(.hidden)

        ToolbarItem(id: "thread.move.archive", placement: .secondaryAction) {
            Button(action: didTapArchive) {
                Label(
                    isArchive ? MailResourcesStrings.Localizable.actionMoveToInbox : MailResourcesStrings.Localizable
                        .actionArchive,
                    asset: isArchive ? Action.moveToInbox.icon : Action.archive.icon
                )
            }
        }
        .defaultCustomization(.hidden)

        ToolbarItem(id: "thread.move.openMovePanel", placement: .secondaryAction) {
            Button { didTap(action: .openMovePanel) } label: {
                Label(Action.openMovePanel.title, asset: Action.openMovePanel.icon)
            }
        }
        .defaultCustomization(.hidden)

        ToolbarItem(id: "thread.move.delete", placement: .secondaryAction) {
            Button { didTap(action: .delete) } label: {
                Label(Action.delete.title, asset: Action.delete.icon)
            }
        }
        .defaultCustomization(.hidden)
    }

    @ToolbarContentBuilder
    private func toolbarItemReply() -> some CustomizableToolbarContent {
        ToolbarItem(id: "thread.reply.reply", placement: .topBarLeading) {
            Button { didTap(action: .reply) } label: {
                Label(Action.reply.title, asset: Action.reply.icon)
            }
        }
        .defaultCustomization(.visible, options: .alwaysAvailable)

        ToolbarItem(id: "thread.reply.forward", placement: .topBarLeading) {
            Button { didTap(action: .forward) } label: {
                Label(Action.forward.title, asset: Action.forward.icon)
            }
        }
        .defaultCustomization(.visible, options: .alwaysAvailable)

        ToolbarItem(id: "thread.reply.replyAll", placement: .topBarLeading) {
            Button { didTap(action: .replyAll) } label: {
                Label(Action.replyAll.title, asset: Action.replyAll.icon)
            }
        }
        .defaultCustomization(.visible, options: .alwaysAvailable)
    }

    private func didTapFlag() {
        Task {
            await tryOrDisplayError {
                try await actionsManager.performAction(
                    target: frozenMessages,
                    action: isFlagged ? .unstar : .star,
                    origin: .toolbarLarge(originFolder: frozenFolder)
                )
            }
        }
    }

    private func didTapRead() {
        Task {
            await tryOrDisplayError {
                try await actionsManager.performAction(
                    target: frozenMessages,
                    action: isRead ? .markAsUnread : .markAsRead,
                    origin: .toolbarLarge(originFolder: frozenFolder)
                )
            }
        }
    }

    private func didTapArchive() {
        Task {
            await tryOrDisplayError {
                try await actionsManager.performAction(
                    target: frozenMessages,
                    action: isArchive ? .moveToInbox : .archive,
                    origin: .toolbarLarge(originFolder: frozenFolder)
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
}
