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
    /// - Returns: The last message of the list which is not a draft and if possible not from the user's address eg. a reply
    public func lastMessageToExecuteAction(currentMailboxEmail: String) -> Message? {
        if let message = last(where: { $0.isDraft == false && $0.fromMe(currentMailboxEmail: currentMailboxEmail) == false }) {
            return message
        } else if let message = last(where: { $0.isDraft == false }) {
            return message
        }
        return last
    }

    /// - Returns: The `lastMessageToExecuteAction` to execute an action for each unique thread.
    ///
    /// - For a list of messages coming from different threads: `lastMessageToExecuteAction` for each unique thread in the given
    /// folder
    ///
    /// - For a list of messages all coming from the same thread: `lastMessageToExecuteAction`
    func lastMessagesAndDuplicatesToExecuteAction(currentMailboxEmail: String, currentFolder: Folder?) -> [Message] {
        if isSingleMessage(currentFolder: currentFolder) {
            return addingDuplicates()
        } else {
            return uniqueThreadsInFolder(currentFolder)
                .compactMap { $0.lastMessageToExecuteAction(currentMailboxEmail: currentMailboxEmail)
                }
                .addingDuplicates()
        }
    }

    /// - Returns: The original message list and their duplicates
    func addingDuplicates() -> [Message] {
        return self + flatMap(\.duplicates)
    }

    /// - Returns: An array of unique threads to which the given messages belong in a given folder
    func uniqueThreadsInFolder(_ folder: Folder?) -> [Thread] {
        return Set(flatMap(\.threads)).filter { $0.folder?.id == folder?.id }.toArray()
    }

    /// Check if the given list is only composed of one message.
    /// - Returns: `true` if the list contains one message and it's not a one message thread.
    func isSingleMessage(currentFolder: Folder?) -> Bool {
        guard count == 1 else {
            return false
        }

        guard let firstMessageThread = first?.threads.first(where: { $0.folder == currentFolder }) else {
            return false
        }

        return firstMessageThread.messages.count > 1
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
                        .wrappedValue = FlushAlertState(deletedMessages: messagesWithDuplicates
                            .uniqueThreadsInFolder(origin.folder).count) {
                                await tryOrDisplayError { [weak self] in
                                    try await self?.performDelete(messages: messagesWithDuplicates, originFolder: origin.folder)
                                }
                        }
                }
                return
            }

            try await performDelete(messages: messagesWithDuplicates, originFolder: origin.folder)
        case .reply:
            try replyOrForward(messages: messagesWithDuplicates, mode: .reply)
        case .replyAll:
            try replyOrForward(messages: messagesWithDuplicates, mode: .replyAll)
        case .forward:
            try replyOrForward(messages: messagesWithDuplicates, mode: .forward)
        case .archive:
            let messagesFromFolder = messagesWithDuplicates.filter { $0.folderId == origin.folder?.id }
            try await performMove(messages: messagesFromFolder, from: origin.folder, to: .archive)
        case .markAsRead:
            try await mailboxManager.markAsSeen(messages: messagesWithDuplicates, seen: true)
        case .markAsUnread:
            let messagesToExecuteAction = messagesWithDuplicates.lastMessagesAndDuplicatesToExecuteAction(
                currentMailboxEmail: mailboxManager.mailbox.email,
                currentFolder: origin.folder
            )
            try await mailboxManager.markAsSeen(messages: messagesToExecuteAction, seen: false)
        case .openMovePanel:
            Task { @MainActor in
                origin.nearestMessagesToMoveSheet?.wrappedValue = messagesWithDuplicates
            }
        case .star:
            let messagesToExecuteAction = messagesWithDuplicates.lastMessagesAndDuplicatesToExecuteAction(
                currentMailboxEmail: mailboxManager.mailbox.email,
                currentFolder: origin.folder
            )
            try await mailboxManager.star(messages: messagesToExecuteAction, starred: true)
        case .unstar:
            try await mailboxManager.star(messages: messagesWithDuplicates, starred: false)
        case .moveToInbox, .nonSpam:
            try await performMove(messages: messagesWithDuplicates, from: origin.folder, to: .inbox)
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
            let messagesFromFolder = messagesWithDuplicates.filter { $0.folderId == origin.folder?.id }
            try await performMove(messages: messagesFromFolder, from: origin.folder, to: .spam)
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

    private func performMove(messages: [Message], from originFolder: Folder?, to folderRole: FolderRole) async throws {
        let undoAction = try await mailboxManager.move(messages: messages, to: folderRole)
        let snackbarMessage = snackbarMoveMessage(
            for: messages,
            originFolder: originFolder,
            destinationFolderName: folderRole.localizedName
        )

        async let _ = await displayResultSnackbar(message: snackbarMessage, undoAction: undoAction)
    }

    public func performMove(messages: [Message], from originFolder: Folder?, to destinationFolder: Folder) async throws {
        let messagesFromFolder = messages.filter { $0.folderId == originFolder?.id }
        let undoAction = try await mailboxManager.move(messages: messagesFromFolder, to: destinationFolder)

        let snackbarMessage = snackbarMoveMessage(
            for: messagesFromFolder,
            originFolder: originFolder,
            destinationFolderName: destinationFolder.localizedName
        )

        async let _ = await displayResultSnackbar(message: snackbarMessage, undoAction: undoAction)
    }

    private func performDelete(messages: [Message], originFolder: Folder?) async throws {
        if originFolder?.role == .trash
            || originFolder?.role == .spam
            || originFolder?.role == .draft {
            try await mailboxManager.delete(messages: messages)
            let snackbarMessage = snackbarPermanentlyDeleteMessage(for: messages, originFolder: originFolder)
            async let _ = await displayResultSnackbar(message: snackbarMessage, undoAction: nil)
        } else {
            try await performMove(messages: messages, from: originFolder, to: .trash)
        }
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
            let draft = Draft.replying(
                reply: MessageReply(message: replyingMessage, replyMode: mode),
                currentMailboxEmail: mailboxManager.mailbox.email
            )
            navigationState?.editedMessageDraft = draft
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
                return MailResourcesStrings.Localizable.snackbarThreadsMoved(destinationFolderName)
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
}
