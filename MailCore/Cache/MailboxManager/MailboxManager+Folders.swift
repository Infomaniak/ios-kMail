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
import InfomaniakCore
import InfomaniakCoreUI
import RealmSwift

// MARK: - Folders

public extension MailboxManager {
    /// Get all remote folders in DB
    func refreshAllFolders() async throws {
        let backgroundTracker = await ApplicationBackgroundTaskTracker(identifier: #function + UUID().uuidString)

        // Network check
        guard ReachabilityListener.instance.currentStatus != .offline else {
            return
        }

        // Get from API
        let folderResult = try await observeAPIErrors { try await self.apiFetcher.folders(mailbox: self.mailbox) }
        let newFolders = getSubFolders(from: folderResult)

        await backgroundRealm.execute { realm in
            for folder in newFolders {
                self.keepCacheAttributes(for: folder, using: realm)
            }

            // Get from Realm
            let cachedFolders = realm.objects(Folder.self)

            // Update folders in Realm
            try? realm.safeWrite {
                // Remove old folders
                realm.add(folderResult, update: .modified)
                let toDeleteFolders = Set(cachedFolders).subtracting(Set(newFolders)).filter { $0.id != Constants.searchFolderId }
                var toDeleteThreads = [Thread]()

                // Threads contains in folders to delete
                let mayBeDeletedThreads = Set(toDeleteFolders.flatMap(\.threads))
                // Messages contains in folders to delete
                let toDeleteMessages = Set(toDeleteFolders.flatMap(\.messages))

                // Delete thread if all his messages are deleted
                for thread in mayBeDeletedThreads where Set(thread.messages).isSubset(of: toDeleteMessages) {
                    toDeleteThreads.append(thread)
                }

                realm.delete(toDeleteMessages)
                realm.delete(toDeleteThreads)
                realm.delete(toDeleteFolders)
            }
        }

        await backgroundTracker.end()
    }

    /// Get the folder with the corresponding role in Realm.
    /// - Parameters:
    ///   - role: Role of the folder.
    /// - Returns: The folder with the corresponding role, or `nil` if no such folder has been found.
    func getFolder(with role: FolderRole) -> Folder? {
        let realm = getRealm() // Always a new realm, so access is from the correct thread
        return realm.objects(Folder.self).where { $0.role == role }.first
    }

    /// Get all the real folders in Realm
    /// - Parameters:
    ///   - realm: The Realm instance to use. If this parameter is `nil`, a new one will be created.
    /// - Returns: The list of real folders.
    func getFolders(using realm: Realm? = nil) -> [Folder] {
        let realm = realm ?? getRealm()
        return Array(realm.objects(Folder.self).where { $0.toolType == nil })
    }

    func createFolder(name: String, parent: Folder? = nil) async throws -> Folder {
        var folder = try await observeAPIErrors {
            try await self.apiFetcher.create(
                mailbox: self.mailbox,
                folder: NewFolder(name: name, path: parent?.path)
            )
        }

        await backgroundRealm.execute { realm in
            try? realm.safeWrite {
                realm.add(folder)
                if let parent {
                    parent.fresh(using: realm)?.children.insert(folder)
                }
            }
            folder = folder.freeze()
        }
        return folder
    }

    // MARK: RefreshActor

    func flushFolder(folder: Folder) async throws -> Bool {
        return try await refreshActor.flushFolder(folder: folder, mailbox: mailbox, apiFetcher: apiFetcher)
    }

    func refreshFolder(from messages: [Message], additionalFolder: Folder? = nil) async throws {
        try await refreshActor.refreshFolder(from: messages, additionalFolder: additionalFolder)
    }

    func refreshFolderContent(_ folder: Folder) async {
        await refreshActor.refreshFolderContent(folder)
    }

    func cancelRefresh() async {
        await refreshActor.cancelRefresh()
    }
}
