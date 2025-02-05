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
    func snooze(messages: [Message], until date: Date, mailbox: Mailbox) async throws {
        let _: Empty = try await perform(
            request: authenticatedRequest(
                .snooze(uuid: mailbox.uuid),
                method: .post,
                parameters: MessagesToSnooze(endDate: date, uids: messages.map(\.uid))
            )
        )
    }

    func updateSnooze(messages: [Message], until date: Date) async throws {
        // TODO: API Should be updated to allow batch actions
        for message in messages {
            let _: Empty = try await perform(
                request: authenticatedRequest(
                    .snoozeAction(resource: ""),
                    method: .put,
                    parameters: ["end_date": date]
                )
            )
        }
    }

    func deleteSnooze(messages: [Message]) async throws {
        // TODO: API Should be updated to allow batch actions
        for message in messages {
            let _: Empty = try await perform(
                request: authenticatedRequest(
                    .snoozeAction(resource: ""),
                    method: .delete
                )
            )
        }
    }
}
