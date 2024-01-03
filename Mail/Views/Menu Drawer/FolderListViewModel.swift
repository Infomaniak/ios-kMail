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

import Combine
import Foundation
import MailCore
import RealmSwift
import SwiftUI

struct NestableFolder: Identifiable {
    var id: Int {
        // The id of a folder depends on its `remoteId` and the id of its children
        // Compute the id by doing an XOR with the id of each child
        return children.reduce(content.remoteId.hashValue) { $0 ^ $1.id }
    }

    let content: Folder
    let children: [NestableFolder]

    static func createFoldersHierarchy(from folders: [Folder]) -> [Self] {
        var parentFolders = [NestableFolder]()

        for folder in folders {
            parentFolders.append(NestableFolder(
                content: folder,
                children: createFoldersHierarchy(from: Array(folder.children))
            ))
        }

        return parentFolders
    }
}

final class FolderListViewModel: ObservableObject {
    @Published var roleFolders = [NestableFolder]()
    @Published var userFolders = [NestableFolder]()

    @Published var searchQuery = ""

    private var foldersObservationToken: NotificationToken?
    private var searchQueryObservation: AnyCancellable?
    private var folders: Results<Folder>?

    init(mailboxManager: MailboxManager) {
        updateFolderListForMailboxManager(mailboxManager, animateInitialChanges: false)

        searchQueryObservation = $searchQuery
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let folders = self?.folders else { return }
                self?.filterAndSortFolders(folders)
            }
    }

    func updateFolderListForMailboxManager(_ mailboxManager: MailboxManager, animateInitialChanges: Bool) {
        foldersObservationToken = mailboxManager.getRealm()
            // swiftlint:disable:next empty_count
            .objects(Folder.self).where { $0.parents.count == 0 && $0.toolType == nil }
            .observe(on: DispatchQueue.main) { [weak self] results in
                switch results {
                case .initial(let folders):
                    withAnimation(animateInitialChanges ? .default : nil) {
                        self?.folders = folders.freezeIfNeeded()
                        self?.filterAndSortFolders(folders.freezeIfNeeded())
                    }
                case .update(let folders, _, _, _):
                    withAnimation {
                        self?.folders = folders.freezeIfNeeded()
                        self?.filterAndSortFolders(folders.freezeIfNeeded())
                    }
                case .error:
                    break
                }
            }
    }

    private func filterAndSortFolders(_ folders: Results<Folder>) {
        let filteredFolders = filterFolders(folders)

        let sortedRoleFolders = filteredFolders.filter { $0.role != nil }.sorted()
        roleFolders = createFoldersHierarchy(from: sortedRoleFolders)

        // sort Folders with case insensitive compare
        let sortedUserFolders = filteredFolders.filter { $0.role == nil }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        userFolders = createFoldersHierarchy(from: sortedUserFolders)
    }

    private func filterFolders(_ folders: Results<Folder>) -> [Folder] {
        guard !searchQuery.isEmpty else {
            return Array(folders)
        }

        return folders.filter {
            let filter = searchQuery.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            return $0.verifyFilter(filter)
        }
    }

    private func createFoldersHierarchy(from folders: [Folder]) -> [NestableFolder] {
        if searchQuery.isEmpty {
            return NestableFolder.createFoldersHierarchy(from: folders)
        } else {
            return folders.map { NestableFolder(content: $0, children: []) }
        }
    }
}