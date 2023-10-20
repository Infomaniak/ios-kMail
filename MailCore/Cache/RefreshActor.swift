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
import InfomaniakCoreUI

public actor RefreshActor {
    weak var mailboxManager: MailboxManager?

    private var refreshTask: Task<Void, Never>?

    public init(mailboxManager: MailboxManager) {
        self.mailboxManager = mailboxManager
    }

    public func flushFolder(folder: Folder, mailbox: Mailbox, apiFetcher: MailApiFetcher) async throws -> Bool {
        let response = try await apiFetcher.flushFolder(mailbox: mailbox, folderId: folder.remoteId)
        await refreshFolderContent(folder)
        return response
    }

    public func refreshFolder(from messages: [Message], additionalFolder: Folder?) async throws {
        let updateFolders = Task {
            var folders = messages.map(\.folder)
            if let additionalFolder {
                folders.append(additionalFolder)
            }

            let orderedSet = NSOrderedSet(array: folders as [Any])

            for folder in orderedSet {
                guard !Task.isCancelled else { break }
                guard let impactedFolder = folder as? Folder else { continue }
                await refreshFolderContent(impactedFolder)
            }
        }

        // Track progress in background with a cancelation handler
        let backgroundTracker = await ApplicationBackgroundTaskTracker(identifier: #function + UUID().uuidString) {
            updateFolders.cancel()

            Task {
                await self.cancelRefresh()
            }
        }

        await updateFolders.finish()

        await backgroundTracker.end()
    }

    public func refreshFolderContent(_ folder: Folder) async {
        await cancelRefresh()

        refreshTask = Task {
            await tryOrDisplayError {
                try await mailboxManager?.threads(folder: folder)
                refreshTask = nil
            }
        }
        _ = await refreshTask?.result
    }

    public func cancelRefresh() async {
        refreshTask?.cancel()
        _ = await refreshTask?.result
        refreshTask = nil
    }
}
