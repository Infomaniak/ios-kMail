/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailResources
import Sentry
import SwiftUI

extension [Message]: @retroactive Identifiable {
    public var id: Int {
        var hasher = Hasher()
        forEach { hasher.combine($0.hashValue) }
        return hasher.finalize()
    }
}

extension RandomAccessCollection where Element == Message {
    /// - Returns: The last message of the list which is not a draft and if possible not from the user's address eg. a reply
    public func lastMessageToExecuteAction(currentMailboxEmail: String) -> Message? {
        var canExecuteActionAndIsNotFromMe: Message?
        var canExecuteAction: Message?
        for message in self {
            if message.canExecuteAction {
                canExecuteAction = message
                if !message.fromMe(currentMailboxEmail: currentMailboxEmail) {
                    canExecuteActionAndIsNotFromMe = message
                }
            }
        }

        return canExecuteActionAndIsNotFromMe ?? canExecuteAction ?? last
    }

    func lastMessagesToExecuteAction(currentMailboxEmail: String, currentFolder: Folder?) -> [Message] {
        if isSingleMessage(currentFolder: currentFolder) || currentFolder?.toolType == .search {
            return Array(self)
        } else {
            return uniqueThreadsInFolder(currentFolder)
                .compactMap { $0.lastMessageToExecuteAction(currentMailboxEmail: currentMailboxEmail) }
        }
    }

    /// - Returns: The `lastMessageToExecuteAction` to execute an action for each unique thread.
    ///
    /// - For a list of messages coming from different threads: `lastMessageToExecuteAction` for each unique thread in the given
    /// folder
    ///
    /// - For a list of messages all coming from the same thread: `lastMessageToExecuteAction`
    func lastMessagesAndDuplicatesToExecuteAction(currentMailboxEmail: String, currentFolder: Folder?) -> [Message] {
        let messages = lastMessagesToExecuteAction(currentMailboxEmail: currentMailboxEmail, currentFolder: currentFolder)
        return messages.addingDuplicates()
    }

    func fromFolderOrSearch(originFolder: Folder?) -> [Message] {
        return originFolder?.toolType == .search ?
            self as! [Message] :
            filter { $0.folderId == originFolder?.remoteId }
    }

    /// - Returns: The original message list and their duplicates
    func addingDuplicates() -> [Message] {
        return self + flatMap(\.duplicates)
    }

    /// - Returns: An array of unique threads to which the given messages belong in a given folder
    func uniqueThreadsInFolder(_ folder: Folder?) -> [Thread] {
        return Set(flatMap(\.threads)).filter { $0.folder?.remoteId == folder?.remoteId }.toArray()
    }

    /// Check if the given list is only composed of one message.
    /// - Returns: `true` if the list contains one message and it's not a one message thread.
    func isSingleMessage(currentFolder: Folder?) -> Bool {
        guard count == 1 else {
            return false
        }

        guard let firstMessageThread = first?.threads.first(where: { $0.folder?.remoteId == currentFolder?.remoteId }) else {
            return false
        }

        return firstMessageThread.messages.count > 1
    }
}

public class ActionsManager: ObservableObject {
    @LazyInjectService private var snackbarPresenter: IKSnackBarPresentable
    @LazyInjectService private var platformDetector: PlatformDetectable

    private let mailboxManager: MailboxManager
    private let mainViewState: MainViewState?

    public init(mailboxManager: MailboxManager, mainViewState: MainViewState?) {
        self.mailboxManager = mailboxManager
        self.mainViewState = mainViewState
    }

    public func performAction(target messages: [Message], action: Action, origin: ActionOrigin) async throws {
        let messagesWithDuplicates = messages.addingDuplicates()

        switch action {
        case .delete:
            guard origin.frozenFolder?.shouldWarnBeforeDeletion != true else {
                await showWarningDeletionAlert(origin: origin, messagesWithDuplicates: messagesWithDuplicates)
                return
            }

            guard !messagesWithDuplicates.contains(where: { $0.isSnoozed }) else {
                await showWarningDeleteSnoozeAlert(origin: origin, messagesWithDuplicates: messagesWithDuplicates)
                return
            }

            try await performDelete(messages: messagesWithDuplicates, originFolder: origin.frozenFolder)
        case .reply:
            try replyOrForward(messages: messagesWithDuplicates, mode: .reply)
        case .replyAll:
            try replyOrForward(messages: messagesWithDuplicates, mode: .replyAll)
        case .forward:
            try replyOrForward(messages: messagesWithDuplicates, mode: .forward)
        case .archive:
            let messagesFromFolder = messagesWithDuplicates.fromFolderOrSearch(originFolder: origin.frozenFolder)
            guard !messagesWithDuplicates.contains(where: { $0.isSnoozed }) else {
                await showWarningArchiveSnoozeAlert(origin: origin, messagesFromFolder: messagesFromFolder)
                return
            }

            try await performMove(messages: messagesFromFolder, from: origin.frozenFolder, to: .archive)
        case .markAsRead:
            try await mailboxManager.markAsSeen(messages: messagesWithDuplicates, seen: true)
        case .markAsUnread:
            let messagesToExecuteAction = messages.lastMessagesAndDuplicatesToExecuteAction(
                currentMailboxEmail: mailboxManager.mailbox.email,
                currentFolder: origin.frozenFolder
            )
            try await mailboxManager.markAsSeen(messages: messagesToExecuteAction, seen: false)
        case .openMovePanel:
            guard !messagesWithDuplicates.contains(where: { $0.isSnoozed }) else {
                await showWarningMoveSnoozeAlert(origin: origin, messagesWithDuplicates: messagesWithDuplicates)
                return
            }
            Task { @MainActor in
                origin.nearestMessagesToMoveSheet?.wrappedValue = messagesWithDuplicates
            }
        case .star:
            let messagesToExecuteAction = messages.lastMessagesAndDuplicatesToExecuteAction(
                currentMailboxEmail: mailboxManager.mailbox.email,
                currentFolder: origin.frozenFolder
            )
            try await mailboxManager.star(messages: messagesToExecuteAction, starred: true)
        case .unstar:
            try await mailboxManager.star(messages: messagesWithDuplicates, starred: false)
        case .print:
            guard let message = messages.first else { return }
            // Needed to be sure that the bottomView is dismissed before we try to show the printPanel
            DispatchQueue.main.asyncAfter(deadline: UIConstants.modalCloseDelay) {
                let nc = NotificationCenter.default
                nc.post(name: Notification.Name.printNotification, object: message)
            }
        case .moveToInbox, .nonSpam:
            try await performMove(messages: messagesWithDuplicates, from: origin.frozenFolder, to: .inbox)
        case .quickActionPanel:
            Task { @MainActor in
                origin.nearestMessagesActionsPanel?.wrappedValue = messagesWithDuplicates
            }
        case .reportJunk:
            Task { @MainActor in
                origin.nearestReportJunkMessagesActionsPanel?.wrappedValue = messagesWithDuplicates
            }
        case .spam:
            let messagesFromFolder = messagesWithDuplicates.fromFolderOrSearch(originFolder: origin.frozenFolder)

            try await performCancelableMove(messages: messagesFromFolder, from: origin.frozenFolder,
                                            to: .spam) { messages, _, originFolder in
                try await self.mailboxManager.reportSpam(messages: messages, origin: originFolder)
            }
        case .phishing:
            Task { @MainActor in
                origin.nearestReportedForPhishingMessagesAlert?.wrappedValue = messagesWithDuplicates
            }
        case .reportDisplayProblem:
            Task { @MainActor in
                origin.nearestReportedForDisplayProblemMessageAlert?.wrappedValue = messagesWithDuplicates.first
            }
        case .block:
            for message in messages {
                try await mailboxManager.apiFetcher.blockSender(message: message)
            }
            snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarSenderBlacklisted(messages.count))
        case .blockList:
            Task { @MainActor in
                let uniqueRecipient = self.getUniqueRecipients(reportedMessages: messages)
                if isMultipleRecipientSingleThread(
                    messages,
                    originFolder: origin.frozenFolder,
                    uniqueRecipientCount: uniqueRecipient.count
                ) {
                    origin.nearestBlockSendersList?.wrappedValue = BlockRecipientState(recipientsToMessage: uniqueRecipient)
                } else {
                    origin.nearestBlockSenderAlert?.wrappedValue = BlockRecipientAlertState(
                        recipients: Array(uniqueRecipient.keys),
                        messages: messages
                    )
                }
            }
        case .saveThreadInkDrive:
            guard !platformDetector.isMac else { return }
            origin.messagesToDownload?.wrappedValue = messages
        case .shareMailLink:
            guard let message = messagesWithDuplicates.first else { return }
            let result = try await mailboxManager.apiFetcher.shareMailLink(message: message)
            Task { @MainActor in
                origin.nearestShareMailLinkPanel?.wrappedValue = result
            }
        case .snooze, .modifySnooze:
            Task { @MainActor in
                origin.nearestMessagesToSnooze?.wrappedValue = messages
            }
        case .cancelSnooze:
            let messagesToExecuteAction = messages.lastMessagesToExecuteAction(
                currentMailboxEmail: mailboxManager.mailbox.email,
                currentFolder: origin.frozenFolder
            )
            try await performDeleteSnooze(messages: messagesToExecuteAction)
        default:
            break
        }
    }

    public func performMove(messages: [Message], from originFolder: Folder?, to folderRole: FolderRole) async throws {
        try await performCancelableMove(
            messages: messages,
            from: originFolder,
            to: folderRole,
            action: mailboxManager.move
        )
    }

    public func performMove(messages: [Message], from originFolder: Folder?, to folder: Folder) async throws {
        try await performCancelableMove(
            messages: messages,
            from: originFolder,
            to: folder,
            action: mailboxManager.move
        )
    }

    private func performCancelableMove(
        messages: [Message],
        from originFolder: Folder?,
        to destinationFolderRole: FolderRole,
        action: @escaping ([Message], Folder, Folder?) async throws -> UndoAction
    ) async throws {
        guard let folder = mailboxManager.getFolder(with: destinationFolderRole)?.freeze() else { throw MailError.folderNotFound }

        try await performCancelableMove(messages: messages, from: originFolder, to: folder, action: action)
    }

    private func performCancelableMove(
        messages: [Message],
        from originFolder: Folder?,
        to destinationFolder: Folder,
        action: @escaping ([Message], Folder, Folder?) async throws -> UndoAction
    ) async throws {
        let task = Task {
            return try await action(messages, destinationFolder, originFolder)
        }

        let undoAction = UndoAction(waitingForAsyncUndoAction: task)

        let snackbarMessage = snackbarMoveMessage(
            for: messages,
            originFolder: originFolder,
            destinationFolderName: destinationFolder.localizedName
        )

        async let _ = await displayResultSnackbar(message: snackbarMessage, undoAction: undoAction)
    }

    private func performDelete(messages: [Message], originFolder: Folder?) async throws {
        if originFolder?.permanentlyDeleteContent == true {
            let permanentlyDeleteTask = Task {
                guard originFolder?.role != .scheduledDrafts else {
                    try await mailboxManager.delete(draftMessages: messages)
                    return
                }
                try await mailboxManager.delete(messages: messages)
            }

            let snackbarMessage = snackbarPermanentlyDeleteMessage(for: messages, originFolder: originFolder)
            async let _ = await displayResultSnackbar(message: snackbarMessage, undoAction: nil)

            try await permanentlyDeleteTask.value
        } else {
            try await performMove(messages: messages, from: originFolder, to: .trash)
        }
    }

    @MainActor
    private func displayResultSnackbar(message: String?, undoAction: UndoAction?) {
        guard let message else { return }

        if let undoAction {
            IKSnackBar.showCancelableSnackBar(
                message: message,
                cancelSuccessMessage: MailResourcesStrings.Localizable.snackbarMoveCancelled,
                undoAction: undoAction
            )
        } else {
            snackbarPresenter.show(message: message)
        }
    }

    @MainActor
    private func showWarningDeletionAlert(origin: ActionOrigin, messagesWithDuplicates: [Message]) {
        origin.nearestDestructiveAlert?.wrappedValue = DestructiveActionAlertState(
            type: .permanentlyDelete(messagesWithDuplicates.uniqueThreadsInFolder(origin.frozenFolder).count)
        ) {
            await tryOrDisplayError { [weak self] in
                try await self?.performDelete(
                    messages: messagesWithDuplicates,
                    originFolder: origin.frozenFolder
                )
            }
        }
    }

    @MainActor
    private func showWarningDeleteSnoozeAlert(origin: ActionOrigin, messagesWithDuplicates: [Message]) {
        origin.nearestDestructiveAlert?.wrappedValue = DestructiveActionAlertState(
            type: .deleteSnooze(messagesWithDuplicates.uniqueThreadsInFolder(origin.frozenFolder).count)
        ) {
            await tryOrDisplayError { [weak self] in
                try await self?.performDelete(
                    messages: messagesWithDuplicates,
                    originFolder: origin.frozenFolder
                )
            }
        }
    }

    @MainActor
    private func showWarningArchiveSnoozeAlert(origin: ActionOrigin, messagesFromFolder: [Message]) {
        origin.nearestDestructiveAlert?.wrappedValue = DestructiveActionAlertState(
            type: .archiveSnooze(messagesFromFolder.uniqueThreadsInFolder(origin.frozenFolder).count)
        ) {
            await tryOrDisplayError { [weak self] in
                try await self?.performMove(messages: messagesFromFolder, from: origin.frozenFolder, to: .archive)
            }
        }
    }

    @MainActor
    private func showWarningMoveSnoozeAlert(origin: ActionOrigin, messagesWithDuplicates: [Message]) {
        origin.nearestDestructiveAlert?.wrappedValue = DestructiveActionAlertState(
            type: .moveSnooze(messagesWithDuplicates.uniqueThreadsInFolder(origin.frozenFolder).count)
        ) {
            tryOrDisplayError {
                origin.nearestMessagesToMoveSheet?.wrappedValue = messagesWithDuplicates
            }
        }
    }

    private func replyOrForward(messages: [Message], mode: ReplyMode) throws {
        guard let replyingMessage = messages.lastMessageToExecuteAction(currentMailboxEmail: mailboxManager.mailbox.email) else {
            throw MailError.localMessageNotFound
        }

        Task { @MainActor in
            mainViewState?.composeMessageIntent = .replyingTo(
                message: replyingMessage,
                replyMode: mode,
                originMailboxManager: mailboxManager
            )
        }
    }

    private func snackbarMoveMessage(for messages: [Message], originFolder: Folder?, destinationFolderName: String) -> String {
        if messages.isSingleMessage(currentFolder: originFolder) {
            return MailResourcesStrings.Localizable.snackbarMessageMoved(destinationFolderName)
        } else {
            let uniqueThreadCount = messages.uniqueThreadsInFolder(originFolder).count
            if uniqueThreadCount == 1 {
                return MailResourcesStrings.Localizable.snackbarThreadMoved(destinationFolderName)
            } else {
                return MailResourcesStrings.Localizable.snackbarThreadMovedPlural(destinationFolderName)
            }
        }
    }

    private func snackbarPermanentlyDeleteMessage(for messages: [Message], originFolder: Folder?) -> String {
        if messages.isSingleMessage(currentFolder: originFolder) {
            return MailResourcesStrings.Localizable.snackbarMessageDeletedPermanently
        } else {
            return MailResourcesStrings.Localizable
                .snackbarThreadDeletedPermanently(messages.uniqueThreadsInFolder(originFolder).count)
        }
    }

    private func getUniqueRecipients(reportedMessages messages: [Message]) -> [Recipient: Message] {
        var uniqueRecipients = [String: Recipient]()
        var recipientToMessage = [Recipient: Message]()

        for reportedMessage in messages {
            guard let recipient = reportedMessage.from.first,
                  !recipient.isMe(currentMailboxEmail: mailboxManager.mailbox.email)
            else {
                continue
            }

            if let existingRecipient = uniqueRecipients[recipient.email] {
                if (existingRecipient.name.isEmpty) && !(recipient.name.isEmpty) {
                    let message = recipientToMessage[existingRecipient]
                    uniqueRecipients[recipient.email] = recipient
                    recipientToMessage[recipient] = message
                    recipientToMessage[existingRecipient] = nil
                }
            } else {
                uniqueRecipients[recipient.email] = recipient
                recipientToMessage[recipient] = reportedMessage
            }
        }
        return recipientToMessage
    }

    private func isMultipleRecipientSingleThread(_ selectedMessages: [Message], originFolder: Folder?,
                                                 uniqueRecipientCount: Int) -> Bool {
        guard let originFolder, !selectedMessages.isEmpty, uniqueRecipientCount > 1 else {
            return false
        }

        let uniqueThreads = Set(selectedMessages.uniqueThreadsInFolder(originFolder))
        return uniqueThreads.count == 1
    }
}

// MARK: - Snooze

extension ActionsManager {
    public func performSnooze(messages: [Message], date: Date, originFolder: Folder?) async throws -> Action {
        let messagesToExecuteAction = messages.lastMessagesToExecuteAction(
            currentMailboxEmail: mailboxManager.mailbox.email,
            currentFolder: originFolder
        )

        let allMessagesAreSnoozed = messagesToExecuteAction.allSatisfy(\.isSnoozed)
        if allMessagesAreSnoozed {
            if messagesToExecuteAction.count == 1, let message = messagesToExecuteAction.first {
                try await modifySnooze(message: message, date: date)
            } else {
                try await modifySnooze(messages: messagesToExecuteAction, date: date)
            }
            return .modifiedSnoozed
        } else {
            try await snooze(messages: messagesToExecuteAction, date: date)
            return .snoozed
        }
    }

    private func performDeleteSnooze(messages: [Message]) async throws {
        if messages.count == 1, let message = messages.first {
            try await deleteSnooze(message: message)
        } else {
            try await deleteSnooze(messages: messages)
        }
    }

    private func snooze(messages: [Message], date: Date) async throws {
        let response = try await mailboxManager.snooze(messages: messages, until: date)

        let snoozeCount = response.reduce(0) { $0 + $1.snoozeActions.count }
        showSnoozeCompletedSnackar(messagesSnoozed: snoozeCount, date: date)
    }

    private func modifySnooze(message: Message, date: Date) async throws {
        try await mailboxManager.updateSnooze(message: message, until: date)
        showSnoozeCompletedSnackar(messagesSnoozed: 1, date: date)
    }

    private func modifySnooze(messages: [Message], date: Date) async throws {
        let response = try await mailboxManager.updateSnooze(messages: messages, until: date)

        let snoozeCount = response.reduce(0) { $0 + $1.updated.count }
        showSnoozeCompletedSnackar(messagesSnoozed: snoozeCount, date: date)
    }

    private func deleteSnooze(message: Message) async throws {
        try await mailboxManager.deleteSnooze(message: message)
        showDeleteSnoozeCompletedSnackar(snoozedDeleted: 1)
    }

    private func deleteSnooze(messages: [Message]) async throws {
        let response = try await mailboxManager.deleteSnooze(messages: messages)

        let deletedSnoozeCount = response.reduce(0) { $0 + $1.cancelled.count }
        showDeleteSnoozeCompletedSnackar(snoozedDeleted: deletedSnoozeCount)
    }

    private func showSnoozeCompletedSnackar(messagesSnoozed: Int, date: Date) {
        if messagesSnoozed == 0 {
            snackbarPresenter.show(message: MailResourcesStrings.Localizable.errorUnknown)
        } else {
            snackbarPresenter.show(
                message: MailResourcesStrings.Localizable.snackbarSnoozeSuccess(date.formatted(.snoozeSnackbar))
            )
        }
    }

    private func showDeleteSnoozeCompletedSnackar(snoozedDeleted: Int) {
        if snoozedDeleted == 0 {
            snackbarPresenter.show(message: MailResourcesStrings.Localizable.errorUnknown)
        } else {
            snackbarPresenter
                .show(message: MailResourcesStrings.Localizable.snackbarUnsnoozeSuccess(snoozedDeleted))
        }
    }
}
