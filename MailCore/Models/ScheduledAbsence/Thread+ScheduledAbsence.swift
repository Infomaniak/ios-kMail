/*
 Infomaniak Mail - iOS App
 Copyright (C) 2026 Infomaniak Network SA

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

enum ScheduledAbsenceThreadRecipients {
    private static let outgoingFolderRoles: Set<FolderRole> = [.sent, .draft, .scheduledDrafts]

    static func involvedRecipients(
        in messages: [Message],
        currentMailboxEmail: String,
        folderRole: (Message) -> FolderRole?
    ) -> [ScheduledAbsenceRecipient] {
        let candidates = messages.flatMap { message in
            let isOutgoing = message.isDraft
                || message.fromMe(currentMailboxEmail: currentMailboxEmail)
                || folderRole(message).map { outgoingFolderRoles.contains($0) } ?? false

            return (isOutgoing ? message.to : message.from)
                .filter { !$0.isMe(currentMailboxEmail: currentMailboxEmail) }
                .map { ScheduledAbsenceRecipient(email: $0.email, name: $0.name) }
        }

        return ScheduledAbsenceLookup.recipients(candidates)
    }
}

public extension Thread {
    func scheduledAbsenceRecipients(isEmojiReactionAvailable: Bool, currentMailboxEmail: String) -> [ScheduledAbsenceRecipient] {
        return ScheduledAbsenceThreadRecipients.involvedRecipients(
            in: Array(displayMessages(isEmojiReactionAvailable: isEmojiReactionAvailable)),
            currentMailboxEmail: currentMailboxEmail
        ) { $0.folder?.role }
    }
}
