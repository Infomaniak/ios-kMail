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

public extension MailboxManager {
    func addReminder(message: Message, reminderDelta: Int) async throws {
        try await apiFetcher.addReminder(
            mailboxUuid: mailbox.uuid,
            folderId: message.folderId,
            messageId: message.uid,
            reminderDelta: reminderDelta
        )
        Task { try await refreshFolder(from: [message], additionalFolder: nil) }
    }

    func updateReminder(message: Message, reminderDelta: Int) async throws {
        guard let reminderId = message.reminder?.uuid else {
            return
        }
        try await apiFetcher.updateReminder(
            mailboxUuid: mailbox.uuid,
            folderId: message.folderId,
            messageId: message.uid,
            reminderId: reminderId,
            reminderDelta: reminderDelta
        )
        Task { try await refreshFolder(from: [message], additionalFolder: nil) }
    }

    func deleteReminder(message: Message) async throws {
        guard let reminderId = message.reminder?.uuid else {
            return
        }
        try await apiFetcher.deleteReminder(
            mailboxUuid: mailbox.uuid,
            folderId: message.folderId,
            messageId: message.uid,
            reminderId: reminderId,
        )
        Task { try await refreshFolder(from: [message], additionalFolder: nil) }
    }
}
