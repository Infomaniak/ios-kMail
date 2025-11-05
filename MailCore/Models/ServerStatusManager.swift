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

@MainActor
public final class ServerStatusManager: ObservableObject {
    @Published public private(set) var serverAvailable = true

    public nonisolated init() {}

    private func setServerAvailable(_ serverAvailable: Bool) {
        self.serverAvailable = serverAvailable
    }

    public nonisolated func updateStatusIfNeeded(using mailboxManager: MailboxManager?) async -> Bool {
        guard let mailboxManager else { return true }

        if await serverAvailable {
            return true
        } else {
            return await updateStatus(using: mailboxManager)
        }
    }

    @discardableResult
    public nonisolated func updateStatus(using mailboxManager: MailboxManager?) async -> Bool {
        guard let mailboxManager else { return true }

        do {
            try await mailboxManager.apiFetcher.checkAPIStatus()

            await setServerAvailable(true)
            return true
        } catch {
            await setServerAvailable(false)
            return false
        }
    }
}
