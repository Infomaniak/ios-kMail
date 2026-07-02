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

import Alamofire
import Foundation

public extension MailApiFetcher {
    func addReminder(mailboxUuid: String, folderId: String, messageId: String, reminderDelta: Int) async throws {
        let _: Empty = try await perform(request: authenticatedRequest(
            .reminder(mailboxUuid: mailboxUuid, folderId: folderId, messageId: messageId),
            method: .post,
            parameters: ["reminder_delta": reminderDelta]
        ))
    }

    func updateReminder(
        mailboxUuid: String,
        folderId: String,
        messageId: String,
        reminderId: String,
        reminderDelta: Int
    ) async throws {
        let _: Empty = try await perform(request: authenticatedRequest(
            .reminder(mailboxUuid: mailboxUuid, folderId: folderId, messageId: messageId, reminderId: reminderId),
            method: .put,
            parameters: ["reminder_delta": reminderDelta]
        ))
    }

    func deleteReminder(mailboxUuid: String, folderId: String, messageId: String, reminderId: String) async throws {
        let _: Empty = try await perform(request: authenticatedRequest(
            .reminder(mailboxUuid: mailboxUuid, folderId: folderId, messageId: messageId, reminderId: reminderId),
            method: .delete
        ))
    }
}
