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

public struct ComposeMessageIntent: Codable, Identifiable, Hashable {
    public enum IntentType: Codable, Hashable {
        case new(fromExtension: Bool)
        case existing(draftLocalUUID: String)
        case existingRemote(messageUid: String)
        case mailTo(mailToURLComponents: URLComponents)
        case writeTo(recipient: Recipient)
        case reply(messageUid: String, replyMode: ReplyMode)
    }

    public let id: UUID
    public let userId: Int?
    public let mailboxId: Int?
    public let type: IntentType

    public var shouldSelectMailbox: Bool {
        userId == nil || mailboxId == nil
    }

    public var isFromOutsideOfApp: Bool {
        switch type {
        case .new(let fromExtension) where fromExtension:
            return true
        case .mailTo:
            return true
        default:
            return false
        }
    }

    init(userId: Int?, mailboxId: Int?, type: IntentType) {
        id = UUID()
        self.userId = userId
        self.mailboxId = mailboxId
        self.type = type
    }

    public static func new(originMailboxManager: MailboxManager? = nil, fromExtension: Bool = false) -> ComposeMessageIntent {
        return ComposeMessageIntent(
            userId: originMailboxManager?.mailbox.userId,
            mailboxId: originMailboxManager?.mailbox.mailboxId,
            type: .new(fromExtension: fromExtension)
        )
    }

    public static func existing(draft: Draft, originMailboxManager: MailboxManageable) -> ComposeMessageIntent {
        return ComposeMessageIntent(
            userId: originMailboxManager.mailbox.userId,
            mailboxId: originMailboxManager.mailbox.mailboxId,
            type: .existing(draftLocalUUID: draft.localUUID)
        )
    }

    public static func existingRemote(messageUid: String, originMailboxManager: MailboxManageable) -> ComposeMessageIntent {
        return ComposeMessageIntent(
            userId: originMailboxManager.mailbox.userId,
            mailboxId: originMailboxManager.mailbox.mailboxId,
            type: .existingRemote(messageUid: messageUid)
        )
    }

    public static func mailTo(mailToURLComponents: URLComponents,
                              originMailboxManager: MailboxManager? = nil) -> ComposeMessageIntent {
        return ComposeMessageIntent(
            userId: originMailboxManager?.mailbox.userId,
            mailboxId: originMailboxManager?.mailbox.mailboxId,
            type: .mailTo(mailToURLComponents: mailToURLComponents)
        )
    }

    public static func writeTo(recipient: Recipient, originMailboxManager: MailboxManager) -> ComposeMessageIntent {
        return ComposeMessageIntent(
            userId: originMailboxManager.mailbox.userId,
            mailboxId: originMailboxManager.mailbox.mailboxId,
            type: .writeTo(recipient: recipient)
        )
    }

    public static func replyingTo(message: Message,
                                  replyMode: ReplyMode,
                                  originMailboxManager: MailboxManager) -> ComposeMessageIntent {
        return ComposeMessageIntent(
            userId: originMailboxManager.mailbox.userId,
            mailboxId: originMailboxManager.mailbox.mailboxId,
            type: .reply(messageUid: message.uid, replyMode: replyMode)
        )
    }
}
