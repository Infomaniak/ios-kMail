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
        if isSingleMessage(currentFolder: currentFolder) || currentFolder?.toolType == .search {
            return addingDuplicates()
        } else {
            return uniqueThreadsInFolder(currentFolder)
                .compactMap { $0.lastMessageToExecuteAction(currentMailboxEmail: currentMailboxEmail)
                }
                .addingDuplicates()
        }
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

        guard let firstMessageThread = first?.threads.first(where: { $0.folder == currentFolder }) else {
            return false
        }

        return firstMessageThread.messages.count > 1
    }
}

public class ActionsManager: ObservableObject {
    @LazyInjectService private var snackbarPresenter: SnackBarPresentable
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
                Task { @MainActor in
                    origin.nearestFlushAlert?
                        .wrappedValue = FlushAlertState(deletedMessages: messagesWithDuplicates
                            .uniqueThreadsInFolder(origin.frozenFolder).count) {
                                await tryOrDisplayError { [weak self] in
                                    try await self?.performDelete(
                                        messages: messagesWithDuplicates,
                                        originFolder: origin.frozenFolder
                                    )
                                }
                        }
                }
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
                origin.nearestReportJunkMessageActionsPanel?.wrappedValue = messagesWithDuplicates
            }
        case .spam:
            let messagesFromFolder = messagesWithDuplicates.fromFolderOrSearch(originFolder: origin.frozenFolder)
            try await performMove(messages: messagesFromFolder, from: origin.frozenFolder, to: .spam)
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
        case .blockList:
            Task { @MainActor in

                let uniqueRecipient = self.getUniqueRecipients(reportedMessages: messages)
                if uniqueRecipient.count > 1 {
                    origin.nearestBlockSendersList?.wrappedValue = BlockRecipientState(recipientsToMessage: uniqueRecipient)
                } else if let recipient = uniqueRecipient.first {
                    origin.nearestBlockSenderAlert?.wrappedValue = BlockRecipientAlertState(
                        recipient: recipient.key,
                        message: messages.first!
                    )
                }
            }
        case .saveMailInkDrive:
            guard !platformDetector.isMac else {
                return
            }
            Task { @MainActor in
                do {
                    let fileURL = try await mailboxManager.apiFetcher.download(messages: [messages.first!])
                    try DeeplinkService().shareFilesToKdrive(fileURL)
                } catch {
                    SentrySDK.capture(error: error)
                }
            }
        case .saveThreadInkDrive:
            guard !platformDetector.isMac else {
                return
            }
            Task { @MainActor in
                do {
                    let filesURL = try await mailboxManager.apiFetcher.download(messages: messages)
                    try DeeplinkService().shareFilesToKdrive(filesURL)
                } catch {
                    SentrySDK.capture(error: error)
                }
            }
        case .shareMailLink:
            guard let message = messagesWithDuplicates.first else { return }
            let result = try await mailboxManager.apiFetcher.shareMailLink(message: message)
            Task { @MainActor in
                origin.nearestShareMailLinkPanel?.wrappedValue = result
            }
        default:
            break
        }
    }

    private func performMove(messages: [Message], from originFolder: Folder?, to folderRole: FolderRole) async throws {
        let moveTask = Task {
            do {
                return try await mailboxManager.move(messages: messages, to: folderRole, origin: originFolder)
            }
        }

        let undoAction = UndoAction(waitingForAsyncUndoAction: moveTask)

        let snackbarMessage = snackbarMoveMessage(
            for: messages,
            originFolder: originFolder,
            destinationFolderName: folderRole.localizedName
        )

        async let _ = await displayResultSnackbar(message: snackbarMessage, undoAction: undoAction)
    }

    public func performMove(messages: [Message], from originFolder: Folder?, to destinationFolder: Folder) async throws {
        let messagesFromFolder = messages.fromFolderOrSearch(originFolder: originFolder)

        let moveTask = Task {
            do {
                return try await mailboxManager.move(
                    messages: messagesFromFolder,
                    to: destinationFolder,
                    origin: originFolder
                )
            }
        }

        let undoAction = UndoAction(waitingForAsyncUndoAction: moveTask)

        let snackbarMessage = snackbarMoveMessage(
            for: messagesFromFolder,
            originFolder: originFolder,
            destinationFolderName: destinationFolder.localizedName
        )

        async let _ = await displayResultSnackbar(message: snackbarMessage, undoAction: undoAction)
    }

    private func performDelete(messages: [Message], originFolder: Folder?) async throws {
        if originFolder?.permanentlyDeleteContent == true {
            let permanentlyDeleteTask = Task {
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
}
