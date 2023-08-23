/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import InfomaniakCoreUI
import InfomaniakDI
import MailResources
import SwiftUI

extension [Message]: Identifiable {
    public var id: Int {
        // Calculate a unique identifier by XORing hash values of messages
        return reduce(1) { $0.hashValue ^ $1.hashValue }
    }
}

extension RandomAccessCollection where Element == Message {
    public func lastMessageToExecuteAction(currentMailboxEmail: String) -> Message? {
        if let message = last(where: { $0.isDraft == false && $0.fromMe(currentMailboxEmail: currentMailboxEmail) == false }) {
            return message
        } else if let message = last(where: { $0.isDraft == false }) {
            return message
        }
        return last
    }

    func lastMessagesAndDuplicatesToExecuteAction(currentMailboxEmail: String) -> [Message] {
        let lastMessages = uniqueThreads.compactMap { $0.lastMessageToExecuteAction(currentMailboxEmail: currentMailboxEmail) }
        return lastMessages + lastMessages.flatMap(\.duplicates)
    }

    func addingDuplicates() -> [Message] {
        return self + flatMap(\.duplicates)
    }

    var uniqueThreads: [Thread] {
        return Set(compactMap(\.originalThread)).toArray()
    }

    var isSingleMessage: Bool {
        guard let firstMessageThreadMessagesCount = first?.originalThread?.messages.count else {
            return false
        }

        return count == 1 && firstMessageThreadMessagesCount > 1
    }
}

public class ActionsManager: ObservableObject {
    @LazyInjectService private var snackbarPresenter: SnackBarPresentable

    private let mailboxManager: MailboxManager
    private let navigationState: NavigationState?

    public init(mailboxManager: MailboxManager, navigationState: NavigationState?) {
        self.mailboxManager = mailboxManager
        self.navigationState = navigationState
    }

    public func performAction(target messages: [Message], action: Action, origin: ActionOrigin) async throws {
        let messagesWithDuplicates = messages.addingDuplicates()

        switch action {
        case .delete:
            guard !shouldDisplayDeleteAlert(messages: messagesWithDuplicates, origin: origin) else {
                Task { @MainActor in
                    origin.nearestFlushAlert?
                        .wrappedValue = FlushAlertState(deletedMessages: messagesWithDuplicates.uniqueThreads.count) {
                            await tryOrDisplayError { [weak self] in
                                try await self?.performDelete(messages: messagesWithDuplicates)
                            }
                        }
                }
                return
            }

            try await performDelete(messages: messagesWithDuplicates)
        case .reply:
            try replyOrForward(messages: messagesWithDuplicates, mode: .reply)
        case .replyAll:
            try replyOrForward(messages: messagesWithDuplicates, mode: .replyAll)
        case .forward:
            try replyOrForward(messages: messagesWithDuplicates, mode: .forward)
        case .archive:
            try await performMove(messages: messagesWithDuplicates, to: .archive)
        case .markAsRead:
            try await mailboxManager.markAsSeen(messages: messagesWithDuplicates, seen: true)
        case .markAsUnread:
            let messagesToExecuteAction = messagesWithDuplicates.lastMessagesAndDuplicatesToExecuteAction(
                currentMailboxEmail: mailboxManager.mailbox.email
            )
            try await mailboxManager.markAsSeen(messages: messagesToExecuteAction, seen: false)
        case .openMovePanel:
            Task { @MainActor in
                origin.nearestMessagesToMoveSheet?.wrappedValue = messagesWithDuplicates
            }
        case .star:
            let messagesToExecuteAction = messagesWithDuplicates.lastMessagesAndDuplicatesToExecuteAction(
                currentMailboxEmail: mailboxManager.mailbox.email
            )
            try await mailboxManager.star(messages: messagesToExecuteAction, starred: true)
        case .unstar:
            try await mailboxManager.star(messages: messagesWithDuplicates, starred: false)
        case .moveToInbox, .nonSpam:
            try await performMove(messages: messagesWithDuplicates, to: .inbox)
        case .quickActionPanel:
            Task { @MainActor in
                origin.nearestMessagesActionsPanel?.wrappedValue = messagesWithDuplicates
            }
        case .reportJunk:
            Task { @MainActor in
                assert(messagesWithDuplicates.count <= 1, "More than one message was passed for junk report")
                origin.nearestReportJunkMessageActionsPanel?.wrappedValue = messagesWithDuplicates.first
            }
        case .spam:
         try await performMove(messages: messagesWithDuplicates, to: .spam)
        case .phishing:
            Task { @MainActor in
                origin.nearestReportedForPhishingMessageAlert?.wrappedValue = messagesWithDuplicates.first
            }
        case .reportDisplayProblem:
            Task { @MainActor in
                origin.nearestReportedForDisplayProblemMessageAlert?.wrappedValue = messagesWithDuplicates.first
            }
        case .block:
            guard let message = messagesWithDuplicates.first else { return }
            try await mailboxManager.apiFetcher.blockSender(message: message)
            snackbarPresenter.show(message: MailResourcesStrings.Localizable.snackbarSenderBlacklisted(1))
        default:
            break
        }
    }

    private func performMove(messages: [Message], to folderRole: FolderRole) async throws {
        let undoAction = try await mailboxManager.move(messages: messages, to: folderRole)
        let snackbarMessage = snackbarMoveMessage(
            for: messages,
            destinationFolderName: folderRole.localizedName
        )

        async let _ = await displayResultSnackbar(message: snackbarMessage, undoAction: undoAction)
    }

    public func performMove(messages: [Message], to folder: Folder) async throws {
        let undoAction = try await mailboxManager.move(messages: messages, to: folder)

        let snackbarMessage = snackbarMoveMessage(
            for: messages,
            destinationFolderName: folder.localizedName
        )

        async let _ = await displayResultSnackbar(message: snackbarMessage, undoAction: undoAction)
    }

    private func performDelete(messages: [Message]) async throws {
        let deletionResults = try await mailboxManager.moveOrDelete(messages: messages)

        // Can eventually be improved if needed
        assert(deletionResults.count <= 1, "For now deletion result should always have only one value")
        guard let firstDeletionResult = deletionResults.first else { return }

        let snackbarMessage: String
        let undoAction: UndoAction?
        switch firstDeletionResult {
        case .permanentlyDeleted:
            snackbarMessage = snackbarPermanentlyDeleteMessage(for: messages)
            undoAction = nil
        case .moved(let resultUndoAction):
            snackbarMessage = snackbarMoveMessage(for: messages, destinationFolderName: FolderRole.trash.localizedName)
            undoAction = resultUndoAction
        }

        async let _ = await displayResultSnackbar(message: snackbarMessage, undoAction: undoAction)
    }

    private func shouldDisplayDeleteAlert(messages: [Message], origin: ActionOrigin) -> Bool {
        if origin.type == .multipleSelection,
           let firstFolderRole = messages.first?.folder?.role,
           [FolderRole.draft, FolderRole.spam, FolderRole.trash].contains(firstFolderRole) {
            return true
        }

        return false
    }

    @MainActor
    private func displayResultSnackbar(message: String?, undoAction: UndoAction?) {
        guard let message else { return }

        if let undoAction {
            IKSnackBar.showCancelableSnackBar(
                message: message,
                cancelSuccessMessage: MailResourcesStrings.Localizable.snackbarMoveCancelled,
                undoAction: undoAction,
                mailboxManager: mailboxManager
            )
        } else {
            snackbarPresenter.show(message: message)
        }
    }

    private func replyOrForward(messages: [Message], mode: ReplyMode) throws {
        guard let replyingMessage = messages.lastMessageToExecuteAction(currentMailboxEmail: mailboxManager.mailbox.email) else {
            throw MailError.localMessageNotFound
        }

        Task { @MainActor in
            navigationState?.messageReply = MessageReply(message: replyingMessage, replyMode: mode)
        }
    }

    private func snackbarMoveMessage(for messages: [Message], destinationFolderName: String) -> String {
        if messages.isSingleMessage {
            return MailResourcesStrings.Localizable.snackbarMessageMoved(destinationFolderName)
        } else {
            let uniqueThreadCount = messages.uniqueThreads.count
            if uniqueThreadCount == 1 {
                return MailResourcesStrings.Localizable.snackbarThreadMoved(destinationFolderName)
            } else {
                return MailResourcesStrings.Localizable.snackbarThreadsMoved(destinationFolderName)
            }
        }
    }

    private func snackbarPermanentlyDeleteMessage(for messages: [Message]) -> String {
        if messages.isSingleMessage {
            return MailResourcesStrings.Localizable.snackbarMessageDeletedPermanently
        } else {
            return MailResourcesStrings.Localizable.snackbarThreadDeletedPermanently(messages.uniqueThreads.count)
        }
    }
}
