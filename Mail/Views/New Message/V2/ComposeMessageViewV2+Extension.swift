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
import MailCore
import RealmSwift

extension ComposeMessageViewV2 {
    static func newMessage(mailboxManager: MailboxManager) -> ComposeMessageViewV2 {
        let draft = Draft(localUUID: UUID().uuidString)
        return ComposeMessageViewV2(draft: draft, mailboxManager: mailboxManager)
    }

    static func replyOrForwardMessage(messageReply: MessageReply, mailboxManager: MailboxManager) -> ComposeMessageViewV2 {
        let draft = Draft.replying(reply: messageReply)
        return ComposeMessageViewV2(draft: draft, mailboxManager: mailboxManager, messageReply: messageReply)
    }

    static func edit(draft: Draft, mailboxManager: MailboxManager) -> ComposeMessageViewV2 {
        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .newMessage, name: "openFromDraft")
        return ComposeMessageViewV2(draft: draft, mailboxManager: mailboxManager)
    }

    static func writingTo(recipient: Recipient, mailboxManager: MailboxManager) -> ComposeMessageViewV2 {
        let draft = Draft.writing(to: recipient)
        return ComposeMessageViewV2(draft: draft, mailboxManager: mailboxManager)
    }

    static func mailTo(urlComponents: URLComponents, mailboxManager: MailboxManager) -> ComposeMessageViewV2 {
        let draft = Draft.mailTo(urlComponents: urlComponents)
        return ComposeMessageViewV2(draft: draft, mailboxManager: mailboxManager)
    }
}
