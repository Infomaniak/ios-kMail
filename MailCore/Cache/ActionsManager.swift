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

    public func lastMessageToExecuteAction(currentMailboxEmail: String) -> Message? {
        if let message = last(where: { $0.isDraft == false && $0.fromMe(currentMailboxEmail: currentMailboxEmail) == false }) {
            return message
        } else if let message = last(where: { $0.isDraft == false }) {
            return message
        }
        return last
    }

    var uniqueThreadCount: Int {
        return Set(compactMap(\.originalThread?.uid)).count
    }

    var isSingleMessage: Bool {
        guard let firstMessageThreadMessagesCount = first?.originalThread?.messages.count else {
            return false
        }

        return count == 1 && firstMessageThreadMessagesCount > 1
    }
}

public struct ActionOrigin {
    public enum ActionOriginType {
        case swipe
        case floatingPanel
        case toolbar
        case multipleSelection
    }

    let type: ActionOriginType
    let nearestActionPanelMessages: Binding<[Message]?>?
    let nearestFlushAlert: Binding<FlushAlertState?>?

    init(
        type: ActionOriginType,
        nearestActionPanelMessages: Binding<[Message]?>? = nil,
        nearestFlushAlert: Binding<FlushAlertState?>? = nil
    ) {
        self.type = type
        self.nearestActionPanelMessages = nearestActionPanelMessages
        self.nearestFlushAlert = nearestFlushAlert
    }

    public static let floatingPanel = ActionOrigin(type: .floatingPanel)
    public static let toolbar = ActionOrigin(type: .toolbar)

    public static func multipleSelection(nearestFlushAlert: Binding<FlushAlertState?>? = nil) -> ActionOrigin {
        return ActionOrigin(type: .multipleSelection, nearestFlushAlert: nearestFlushAlert)
    }

    public static func swipe(nearestActionPanelMessages: Binding<[Message]?>? = nil) -> ActionOrigin {
        return ActionOrigin(type: .swipe, nearestActionPanelMessages: nearestActionPanelMessages)
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
        switch action {
        case .delete:
            guard !shouldDisplayDeleteAlert(messages: messages, origin: origin) else {
                Task { @MainActor in
                    origin.nearestFlushAlert?.wrappedValue = FlushAlertState(deletedMessages: messages.uniqueThreadCount) {
                        await tryOrDisplayError { [weak self] in
                            try await self?.performDelete(messages: messages)
                        }
                    }
                }
                return
            }

            try await performDelete(messages: messages)
        case .reply:
            try replyOrForward(messages: messages, mode: .reply)
        case .replyAll:
            try replyOrForward(messages: messages, mode: .replyAll)
        case .forward:
            try replyOrForward(messages: messages, mode: .forward)
        case .archive:
            let undoAction = try await mailboxManager.move(messages: messages, to: .archive)
            let snackbarMessage = snackbarMoveMessage(for: messages, destinationFolderName: FolderRole.archive.localizedName)

            async let _ = await displayResultSnackbar(message: snackbarMessage, undoAction: undoAction)
        case .markAsRead:
            try await mailboxManager.markAsSeen(messages: messages, seen: true)
        case .markAsUnread:
            try await mailboxManager.markAsSeen(messages: messages, seen: false)
        case .openMovePanel:
            Task { @MainActor in
                navigationState?.messagesToMove = messages
            }
        case .star:
            try await mailboxManager.star(messages: messages, starred: true)
        case .unstar:
            try await mailboxManager.star(messages: messages, starred: false)
        case .moveToInbox:
            let undoAction = try await mailboxManager.move(messages: messages, to: .inbox)
            let snackbarMessage = snackbarMoveMessage(for: messages, destinationFolderName: FolderRole.inbox.localizedName)

            async let _ = await displayResultSnackbar(message: snackbarMessage, undoAction: undoAction)
        case .quickActionPanel:
            Task { @MainActor in
                origin.nearestActionPanelMessages?.wrappedValue = messages
            }
        default:
            break
        }
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
        assert(messages.count == 1, "Cannot reply to more than one message")
        guard let replyingMessage = messages.lastMessageToExecuteAction(currentMailboxEmail: mailboxManager.mailbox.email) else {
            throw MailError.localMessageNotFound
        }

        Task { @MainActor in
            navigationState?.messageReply = MessageReply(message: replyingMessage, replyMode: .replyAll)
        }
    }

    private func snackbarMoveMessage(for messages: [Message], destinationFolderName: String) -> String {
        if messages.isSingleMessage {
            return MailResourcesStrings.Localizable.snackbarMessageMoved(destinationFolderName)
        } else {
            let uniqueThreadCount = messages.uniqueThreadCount
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
            return MailResourcesStrings.Localizable.snackbarThreadDeletedPermanently(messages.uniqueThreadCount)
        }
    }
}
