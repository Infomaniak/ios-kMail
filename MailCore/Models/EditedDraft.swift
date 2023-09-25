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

public struct EditedDraft: Identifiable {
    public var id: ObjectIdentifier {
        return draft.id
    }

    public let draft: Draft
    public let messageReply: MessageReply?

    public static func new() -> EditedDraft {
        return EditedDraft(draft: Draft(localUUID: UUID().uuidString), messageReply: nil)
    }

    public static func existing(draft: Draft) -> EditedDraft {
        return EditedDraft(draft: draft, messageReply: nil)
    }

    public static func mailTo(urlComponents: URLComponents) -> EditedDraft {
        return EditedDraft(draft: Draft.mailTo(urlComponents: urlComponents), messageReply: nil)
    }

    public static func writing(to recipient: Recipient) -> EditedDraft {
        return EditedDraft(draft: Draft.writing(to: recipient), messageReply: nil)
    }

    public static func replying(reply: MessageReply, currentMailboxEmail: String) -> EditedDraft {
        return EditedDraft(draft: Draft.replying(reply: reply, currentMailboxEmail: currentMailboxEmail), messageReply: reply)
    }
}
