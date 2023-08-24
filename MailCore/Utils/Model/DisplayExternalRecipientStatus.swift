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
import RealmSwift

public struct DisplayExternalRecipientStatus {
    public enum State {
        case none
        case one(recipient: Recipient)
        case many
    }

    let mailboxManager: MailboxManager
    let recipientsList: List<Recipient>

    public init(mailboxManager: MailboxManager, recipientsList: List<Recipient>) {
        self.mailboxManager = mailboxManager
        self.recipientsList = recipientsList
    }

    public var state: State {
        var externalList = [Recipient]()
        let recipients = recipientsList
        for recipient in recipients {
            guard externalList.count < 2 else {
                break
            }

            guard recipient.isExternal(mailboxManager: mailboxManager) else {
                continue
            }

            externalList.append(recipient)
        }

        if externalList.isEmpty {
            return .none
        } else if let recipient = externalList.first, externalList.count == 1 {
            return .one(recipient: recipient)
        } else {
            return .many
        }
    }
}
