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

import Alamofire
import Foundation
import InfomaniakCore

/// implementing `MailApiCommonFetchable`
public extension MailApiFetcher {
    private static let snoozeAPILimit = 100

    func snooze(messages: [Message], until date: Date, mailbox: Mailbox) async throws {
        _ = try await batchOver(values: messages, chunkSize: Self.snoozeAPILimit) { chunk in
            let _: Empty = try await self.perform(request: self.authenticatedRequest(
                .snooze(uuid: mailbox.uuid),
                method: .post,
                parameters: MessagesToSnooze(endDate: date, uids: chunk.map(\.uid))
            ))
        }
    }

    func updateSnooze(messages: [Message], until date: Date, mailbox: Mailbox) async throws {
        // TODO: Replace with Snooze UUID instead of message UID
        _ = try await batchOver(values: messages, chunkSize: Self.snoozeAPILimit) { chunk in
            let _: Empty = try await self.perform(request: self.authenticatedRequest(
                .snooze(uuid: mailbox.uuid),
                method: .put,
                parameters: SnoozedMessagesToUpdate(endDate: date, uuids: chunk.map(\.uid))
            ))
        }
    }

    func deleteSnooze(messages: [Message], mailbox: Mailbox) async throws {
        // TODO: Replace with Snooze UUID instead of message UID
        _ = try await batchOver(values: messages, chunkSize: Self.snoozeAPILimit) { chunk in
            let _: Empty = try await self.perform(request: self.authenticatedRequest(
                .snooze(uuid: mailbox.uuid),
                method: .delete,
                parameters: ["uuids": chunk.map(\.uid)]
            ))
        }
    }
}
