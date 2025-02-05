/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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
import InfomaniakCore
import RealmSwift

// MARK: - Folders

public extension MailboxManager {
    /// Get all remote folders in DB
    func refreshAllFolders() async throws {
        guard ReachabilityListener.instance.currentStatus != .offline else {
            return
        }

        let folderResult = try await apiFetcher.folders(mailbox: mailbox)
        let filteredFolderResult = filterOutUnknownFolders(folderResult)
        let newFolders = getSubFolders(from: filteredFolderResult)

        try? writeTransaction { writableRealm in
            // Update folders in Realm
            for folder in newFolders {
                self.keepCacheAttributes(for: folder, using: writableRealm)
            }

            // Get from Realm
            let cachedFolders = writableRealm.objects(Folder.self)

            // Remove old folders
            writableRealm.add(filteredFolderResult, update: .modified)
            let toDeleteFolders = Set(cachedFolders).subtracting(Set(newFolders))
                .filter { $0.remoteId != Constants.searchFolderId }
            var toDeleteThreads = [Thread]()

            // Threads contains in folders to delete
            let mayBeDeletedThreads = Set(toDeleteFolders.flatMap(\.threads))
            // Messages contains in folders to delete
            let toDeleteMessages = Set(toDeleteFolders.flatMap(\.messages))

            // Delete thread if all his messages are deleted
            for thread in mayBeDeletedThreads where Set(thread.messages).isSubset(of: toDeleteMessages) {
                toDeleteThreads.append(thread)
            }

            writableRealm.delete(toDeleteMessages)
            writableRealm.delete(toDeleteThreads)
            writableRealm.delete(toDeleteFolders)
        }
    }

    /// Get the folder with the corresponding role in Realm.
    /// - Parameters:
    ///   - role: Role of the folder.
    /// - Returns: The folder with the corresponding role, or `nil` if no such folder has been found.
    func getFolder(with role: FolderRole) -> Folder? {
        fetchObject(ofType: Folder.self) { partial in
            partial.where { $0.role == role }.first
        }
    }

    /// Get all the real folders in Realm
    /// - Returns: The list of real folders, frozen.
    func getFrozenFolders() -> [Folder] {
        let frozenFolders = fetchResults(ofType: Folder.self) { partial in
            partial
                .where { $0.toolType == nil }
                .freezeIfNeeded()
        }

        return Array(frozenFolders)
    }

    func createFolder(name: String, parent: Folder?) async throws -> Folder {
        let folder = try await apiFetcher.create(mailbox: mailbox, folder: NewFolder(name: name, path: parent?.path))
        try writeTransaction { writableRealm in
            writableRealm.add(folder)
            if let parent {
                parent.fresh(using: writableRealm)?.children.insert(folder)
            }
        }

        let frozenFolder = folder.freeze()
        return frozenFolder
    }

    // MARK: RefreshActor

    func flushFolder(folder: Folder) async throws -> Bool {
        return try await refreshActor.flushFolder(folder: folder, mailbox: mailbox, apiFetcher: apiFetcher)
    }

    func refreshFolder(from messages: [Message], additionalFolder: Folder?) async throws {
        try await refreshActor.refreshFolder(from: messages, additionalFolder: additionalFolder)
    }

    func refreshFolderContent(_ folder: Folder) async {
        await refreshActor.refreshFolderContent(folder)
    }

    func cancelRefresh() async {
        await refreshActor.cancelRefresh()
    }

    private func filterOutUnknownFolders(_ folders: [Folder]) -> [Folder] {
        let filteredFolders: [Folder] = folders.compactMap { folder in
            guard folder.role != .unknown else { return nil }

            let filteredChildren = filterOutUnknownFolders(Array(folder.children))
            folder.children.removeAll()
            folder.children.insert(objectsIn: filteredChildren)

            return folder
        }

        return filteredFolders
    }
}
