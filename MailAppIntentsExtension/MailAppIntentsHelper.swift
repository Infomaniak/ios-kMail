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

import AppIntents
import InfomaniakDI
import MailCore
import OSLog
// MARK: - Helper

@available(iOS 18.0, *)
enum MailAppIntentsHelper {
    // MARK: Message mapping

    static func mapMessage(_ message: Message, mailbox: Mailbox) -> MailMessageEntity {
        let accountEntity = MailAccountEntity(
            id: mailbox.objectId,
            name: mailbox.mailbox,
            emailAddress: mailbox.email
        )
        let mailboxEntity = MailboxEntity(id: mailbox.objectId, name: mailbox.email, account: accountEntity)

        let sender: IntentPerson
        if let fromRecipient = message.from.first {
            sender = IntentPerson(
                identifier: .contact(fromRecipient.email),
                name: .displayName(fromRecipient.name),
                handle: nil
            )
        } else {
            sender = IntentPerson(
                identifier: .applicationDefined("unknown"),
                name: .displayName(""),
                handle: nil
            )
        }

        let bodyAttributedString: AttributedString? = message.body?.value.flatMap { try? AttributedString(markdown: $0) }

        return MailMessageEntity(
            id: message.uid,
            to: Array(message.to.map { MailAppIntentsHelper.mapRecipientToIntentPerson($0) }),
            cc: Array(message.cc.map { MailAppIntentsHelper.mapRecipientToIntentPerson($0) }),
            bcc: Array(message.bcc.map { MailAppIntentsHelper.mapRecipientToIntentPerson($0) }),
            subject: message.subject,
            body: bodyAttributedString,
            attachments: [],
            sender: sender,
            dateSent: message.internalDate,
            dateReceived: message.date,
            isRead: message.seen,
            isJunk: message.isSpam,
            isFlagged: message.flagged,
            account: accountEntity,
            mailbox: mailboxEntity
        )
    }
}
