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

extension ComposeMessageView {
    static func newMessage(_ draft: Draft, mailboxManager: MailboxManager,
                           itemProviders: [NSItemProvider] = []) -> ComposeMessageView {
        return ComposeMessageView(draft: draft, mailboxManager: mailboxManager, attachments: itemProviders)
    }

    static func replyOrForwardMessage(messageReply: MessageReply, mailboxManager: MailboxManager) -> ComposeMessageView {
        let draft = Draft.replying(reply: messageReply, currentMailboxEmail: mailboxManager.mailbox.email)
        return ComposeMessageView(draft: draft, mailboxManager: mailboxManager, messageReply: messageReply)
    }

    static func edit(draft: Draft, mailboxManager: MailboxManager) -> ComposeMessageView {
        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .newMessage, name: "openFromDraft")
        matomo.track(eventWithCategory: .newMessage, action: .data, name: "openLocalDraft", value: !draft.isLoadedRemotely)
        return ComposeMessageView(draft: draft, mailboxManager: mailboxManager)
    }

    static func writingTo(recipient: Recipient, mailboxManager: MailboxManager) -> ComposeMessageView {
        let draft = Draft.writing(to: recipient)
        return ComposeMessageView(draft: draft, mailboxManager: mailboxManager)
    }

    static func mailTo(urlComponents: URLComponents, mailboxManager: MailboxManager) -> ComposeMessageView {
        let draft = Draft.mailTo(urlComponents: urlComponents)
        return ComposeMessageView(draft: draft, mailboxManager: mailboxManager)
    }
}
