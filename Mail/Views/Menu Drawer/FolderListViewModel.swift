/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import Combine
import Foundation
import InfomaniakCoreDB
import MailCore
import RealmSwift
import SwiftUI

@MainActor final class FolderListViewModel: ObservableObject {
    @Published private(set) var roleFolders = [NestableFolder]()
    @Published private(set) var userFolders = [NestableFolder]()

    @Published var searchQuery = ""
    @Published private(set) var isSearching = false

    private let foldersQuery: (Query<Folder>) -> Query<Bool>

    private var foldersObservationToken: NotificationToken?
    private var searchQueryObservation: AnyCancellable?
    private var folders: Results<Folder>?
    private let worker = FolderListViewModelWorker()

    init(mailboxManager: MailboxManageable, foldersQuery: @escaping (Query<Folder>) -> Query<Bool> = { $0.toolType == nil }) {
        self.foldersQuery = foldersQuery
        updateFolderListForMailboxManager(transactionable: mailboxManager, animateInitialChanges: false)

        searchQueryObservation = $searchQuery
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, let folders else { return }
                filterAndSortFolders(folders)
                isSearching = !searchQuery.isEmpty
            }
    }

    func updateFolderListForMailboxManager(transactionable: Transactionable, animateInitialChanges: Bool) {
        let objects = transactionable.fetchResults(ofType: Folder.self) { partial in
            partial.where(foldersQuery)
        }

        foldersObservationToken = objects.observe(on: DispatchQueue.main) { [weak self] results in
            guard let self else {
                return
            }

            switch results {
            case .initial(let folders):
                processObservedFolders(folders, animated: animateInitialChanges)
            case .update(let folders, _, _, _):
                processObservedFolders(folders, animated: true)
            case .error:
                break
            }
        }
    }

    private func processObservedFolders(_ folders: Results<Folder>, animated: Bool) {
        let frozenFolders = folders.freezeIfNeeded()
        self.folders = frozenFolders
        filterAndSortFolders(frozenFolders, animated: animated)
    }

    private func filterAndSortFolders(_ folders: Results<Folder>, animated: Bool = false) {
        Task { @MainActor in
            let result = await worker.filterAndSortFolders(folders, searchQuery: searchQuery)
            withAnimation(animated ? .default : nil) {
                roleFolders = result.roleFolders
                userFolders = result.userFolders
            }
        }
    }
}

/// A worker that will be part of the cooperative thread pool
struct FolderListViewModelWorker {
    func filterAndSortFolders(_ folders: Results<Folder>,
                              searchQuery: String) async -> (roleFolders: [NestableFolder], userFolders: [NestableFolder]) {
        assert(folders.isFrozen, "Expecting frozen objects")
        let filteredFolders = filterFolders(folders, searchQuery: searchQuery)

        let sortedRoleFolders = filteredFolders.filter { $0.role != nil }
            .sorted()
        let sortedUserFolders = filteredFolders.filter { $0.role == nil }
            .sortedByFavoriteAndName()

        async let roleFolders = createFoldersHierarchy(from: sortedRoleFolders, searchQuery: searchQuery)
        async let userFolders = createFoldersHierarchy(from: sortedUserFolders, searchQuery: searchQuery)

        return await (roleFolders, userFolders)
    }

    private func filterFolders(_ folders: Results<Folder>, searchQuery: String) -> [Folder] {
        guard !searchQuery.isEmpty else {
            // swiftlint:disable:next empty_count
            return Array(folders.where { $0.parents.count == 0 })
        }

        return folders.filter {
            let filter = searchQuery.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            return $0.verifyFilter(filter)
        }
    }

    private func createFoldersHierarchy(from folders: [Folder], searchQuery: String) -> [NestableFolder] {
        if searchQuery.isEmpty {
            return NestableFolder.createFoldersHierarchy(from: folders)
        } else {
            return folders.map { NestableFolder(content: $0, children: []) }
        }
    }
}
