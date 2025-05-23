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

import Foundation

public extension MailboxManager {
    func snooze(messages: [Message], until date: Date) async throws -> [SnoozeAPIResponse] {
        let response = try await apiFetcher.snooze(messages: messages, until: date, mailbox: mailbox)
        Task {
            try await refreshFolder(from: messages, additionalFolder: nil)
        }

        return response
    }

    func updateSnooze(message: Message, until date: Date) async throws {
        try await apiFetcher.updateSnooze(message: message, until: date, mailbox: mailbox)
        Task {
            try await refreshFolder(from: [message], additionalFolder: nil)
        }
    }

    func updateSnooze(messages: [Message], until date: Date) async throws -> [SnoozeUpdatedAPIResponse] {
        let response = try await apiFetcher.updateSnooze(messages: messages, until: date, mailbox: mailbox)
        Task {
            try await refreshFolder(from: messages, additionalFolder: nil)
        }

        return response
    }

    func deleteSnooze(message: Message) async throws {
        try await apiFetcher.deleteSnooze(message: message, mailbox: mailbox)
        Task {
            try await refreshFolder(from: [message], additionalFolder: nil)
        }
    }

    func deleteSnooze(messages: [Message]) async throws -> [SnoozeCancelledAPIResponse] {
        let response = try await apiFetcher.deleteSnooze(messages: messages, mailbox: mailbox)
        Task {
            try await refreshFolder(from: messages, additionalFolder: nil)
        }

        return response
    }
}
