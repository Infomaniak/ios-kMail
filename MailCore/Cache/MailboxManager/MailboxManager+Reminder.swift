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
        guard let shortUid = message.shortUid else {
            throw MailError.localMessageNotFound
        }
        try await apiFetcher.addReminder(
            mailboxUuid: mailbox.uuid,
            folderId: message.folderId,
            messageId: shortUid,
            reminderDelta: reminderDelta
        )
        Task { try await refreshFolder(from: [message], additionalFolder: nil) }
    }

    func updateReminder(message: Message, reminderDelta: Int) async throws {
        if let reminderAction = message.reminderAction, message.scheduleDate != nil {
            let result = try await apiFetcher.updateDraftReminder(reminderResource: reminderAction, reminderDelta: reminderDelta)

            try? writeTransaction { writableRealm in
                guard let liveMessage = writableRealm.object(ofType: Message.self, forPrimaryKey: message.uid) else { return }
                liveMessage.reminder = result
            }
        } else {
            guard let reminderId = message.reminder?.uuid else {
                throw MailError.missingReminderID
            }
            guard let shortUid = message.shortUid else {
                throw MailError.localMessageNotFound
            }
            let result: Reminder = try await apiFetcher.updateReminder(
                mailboxUuid: mailbox.uuid,
                folderId: message.folderId,
                messageId: shortUid,
                reminderId: reminderId,
                reminderDelta: reminderDelta
            )
            try? writeTransaction { writableRealm in
                guard let liveMessage = writableRealm.object(ofType: Message.self, forPrimaryKey: message.uid) else { return }
                liveMessage.reminder = result
            }
        }

        Task { try await refreshFolder(from: [message], additionalFolder: nil) }
    }

    func deleteReminder(message: Message) async throws {
        if let reminderAction = message.reminderAction, message.scheduleDate != nil {
            try await apiFetcher.deleteDraftReminder(reminderResource: reminderAction)
        } else {
            guard let reminderId = message.reminder?.uuid else {
                throw MailError.missingReminderID
            }
            guard let shortUid = message.shortUid else {
                throw MailError.localMessageNotFound
            }
            try await apiFetcher.deleteReminder(
                mailboxUuid: mailbox.uuid,
                folderId: message.folderId,
                messageId: shortUid,
                reminderId: reminderId
            )
        }
        try? writeTransaction { writableRealm in
            guard let liveMessage = writableRealm.object(ofType: Message.self, forPrimaryKey: message.uid) else { return }
            liveMessage.reminder = nil
        }
        Task { try await refreshFolder(from: [message], additionalFolder: nil) }
    }
}
