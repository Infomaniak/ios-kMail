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
import MailResources
import SwiftUI

extension [Message]: Identifiable {
    public var id: Int {
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
}

public class ActionsManager: ObservableObject {
    public enum ActionOrigin {
        case swipe
        case floatingPanel
        case toolbar
        case multipleSelection
    }

    private let mailboxManager: MailboxManager
    private let navigationState: NavigationState?

    public init(mailboxManager: MailboxManager, navigationState: NavigationState?) {
        self.mailboxManager = mailboxManager
        self.navigationState = navigationState
    }

    public func performAction(target messages: [Message], action: Action, origin: ActionOrigin) async throws {
        // TODO: Handle snackbar  + Undo here depending on origin
        switch action {
        case .delete:
            try await mailboxManager.moveOrDelete(messages: messages)
        case .reply:
            try replyOrForward(messages: messages, mode: .reply)
        case .replyAll:
            try replyOrForward(messages: messages, mode: .replyAll)
        case .forward:
            try replyOrForward(messages: messages, mode: .forward)
        case .archive:
            try await mailboxManager.move(messages: messages, to: .archive)
        case .markAsRead:
            try await mailboxManager.markAsSeen(messages: messages, seen: true)
        case .markAsUnread:
            try await mailboxManager.markAsSeen(messages: messages, seen: false)
        case .openMovePanel:
            Task { @MainActor in
                navigationState?.messagesToMove = messages
            }
        case .postpone:
            break
        case .star:
            try await mailboxManager.star(messages: messages, starred: true)
        case .unstar:
            try await mailboxManager.star(messages: messages, starred: false)
        default:
            break
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
}
