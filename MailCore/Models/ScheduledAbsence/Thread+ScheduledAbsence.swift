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

/// A thread-safe snapshot of a recipient whose scheduled absences should be looked up.
public struct ScheduledAbsenceRecipient: Sendable, Hashable {
    /// Lowercased email.
    public let email: String
    public let name: String

    public init(email: String, name: String) {
        self.email = email.lowercased()
        self.name = name
    }
}

public enum ScheduledAbsenceThreadRecipients {
    private static let outgoingFolderRoles: Set<FolderRole> = [.sent, .draft, .scheduledDrafts]

    /// Mirrors the web `#syncThreadSendersScheduledAbsences`: for each message, take its `to` recipients when it was
    /// sent by the user (Sent / Drafts / Scheduled drafts folder), otherwise its `from` recipients.
    /// The current mailbox email is excluded, emails are lowercased, deduped (order kept) and limited.
    public static func involvedRecipients(
        in messages: [Message],
        currentMailboxEmail: String,
        limit: Int = ScheduledAbsenceProvider.maxEmails,
        folderRole: (Message) -> FolderRole?
    ) -> [ScheduledAbsenceRecipient] {
        let excludedEmail = currentMailboxEmail.lowercased()
        var seenEmails = Set<String>()
        var result = [ScheduledAbsenceRecipient]()

        for message in messages {
            let isOutgoing = message.isDraft || folderRole(message).map { outgoingFolderRoles.contains($0) } ?? false
            let recipients = isOutgoing ? message.to : message.from

            for recipient in recipients {
                let email = recipient.email.lowercased()
                guard !email.isEmpty, email != excludedEmail, seenEmails.insert(email).inserted else { continue }

                result.append(ScheduledAbsenceRecipient(email: email, name: recipient.name))
                if result.count >= limit {
                    return result
                }
            }
        }

        return result
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
