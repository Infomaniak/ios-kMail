/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import RealmSwift
import SwiftUI

enum SearchFieldValueType: String {
    case contact
    case threads
    case threadsAndContacts
}

enum SearchState {
    case history
    case results
    case noResults
}

final class SearchViewModel: ObservableObject, ThreadListable {
    var frozenFolder: Folder {
        return frozenSearchFolder
    }

    let mailboxManager: MailCore.MailboxManager

    @LazyInjectService var matomo: MatomoUtils

    @Published var searchValue = ""

    @Published var selectedFilters: [SearchFilter] = [] {
        willSet {
            // cancel current running tasks
            stopObserveSearch()
            currentSearchTask?.cancel()
            frozenThreads = []
        }
    }

    /// Frozen underlying `Folder`
    @Published var frozenRealFolder: Folder

    /// The frozen `Folder` list
    @Published var frozenFolderList: [Folder]

    /// Frozen `Thread` list
    @Published var frozenThreads: [Thread] = []

    /// Frozen `Recipient` list
    @Published var frozenContacts: [Recipient] = []

    @Published var isLoading = false

    @Published var selectedSearchFolderId = "" {
        didSet {
            matomo.track(eventWithCategory: .search, name: SearchFilter.folder.matomoName, value: !selectedSearchFolderId.isEmpty)
            if selectedSearchFolderId.isEmpty {
                selectedFilters.removeAll { $0 == .folder }
            } else if !selectedFilters.contains(.folder) {
                selectedFilters.append(.folder)
            }

            currentSearchTask?.cancel()
            currentSearchTask = Task.detached {
                await self.fetchThreads()
            }
        }
    }

    var searchState: SearchState {
        if selectedFilters.isEmpty && searchValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .history
        } else if !isLoading && lastSearch != nil && frozenThreads.isEmpty && frozenContacts.isEmpty {
            return .noResults
        } else {
            return .results
        }
    }

    /// Token to observe the search itself
    var observationSearchThreadToken: NotificationToken?

    /// Token to observe the fetched search results changes
    var observationSearchResultsChangesToken: NotificationToken?

    var filters: [SearchFilter] = [.folder, .read, .unread, .favorite, .attachment]

    var searchValueType: SearchFieldValueType = .threadsAndContacts

    var selectedThreadOwner: SelectedThreadOwnable

    /// The searchFolders, stored Frozen.
    let frozenSearchFolder: Folder

    var resourceNext: String?

    var lastSearch: String?

    var searchFieldObservation: AnyCancellable?

    var currentSearchTask: Task<Void, Never>?

    let observeQueue = DispatchQueue(label: "com.infomaniak.observation.SearchViewModel", qos: .userInteractive)

    init(mailboxManager: MailboxManager, folder: Folder, selectedThreadOwner: SelectedThreadOwnable) {
        self.selectedThreadOwner = selectedThreadOwner
        self.mailboxManager = mailboxManager
        frozenRealFolder = folder.freezeIfNeeded()
        frozenSearchFolder = mailboxManager.initSearchFolder().freezeIfNeeded()
        frozenFolderList = mailboxManager.getFrozenFolders()
        if folder.role != .inbox {
            selectedSearchFolderId = folder.remoteId
        }

        searchFieldObservation = $searchValue
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { [weak self] newValue in
                guard let self,
                      lastSearch?.trimmingCharacters(in: .whitespacesAndNewlines) != newValue
                      .trimmingCharacters(in: .whitespacesAndNewlines) else {
                    return
                }
                lastSearch = newValue
                searchValueType = .threadsAndContacts
                performSearch()
            }
    }

    func updateContactSuggestion() {
        let autocompleteContacts = mailboxManager.contactManager.frozenContacts(
            matching: searchValue,
            fetchLimit: nil,
            sorted: nil
        )
        var autocompleteRecipients = autocompleteContacts.map { Recipient(email: $0.email, name: $0.name).freezeIfNeeded() }

        // Append typed email
        if EmailChecker(email: searchValue).validate() && !frozenContacts
            .contains(where: { $0.email.caseInsensitiveCompare(searchValue) == .orderedSame }) {
            autocompleteRecipients.append(Recipient(email: searchValue, name: "").freezeIfNeeded())
        }

        let contactRange: Range<Int> = 0 ..< min(autocompleteRecipients.count, Constants.contactSuggestionLimit)
        withAnimation {
            frozenContacts = Array(autocompleteRecipients[contactRange])
        }
    }

    func fetchThreads() async {
        guard !isLoading else {
            return
        }

        isLoading = true
        stopObserveSearch()
        frozenThreads = []

        var folderToSearch = frozenRealFolder.remoteId

        if selectedFilters.contains(.folder) {
            folderToSearch = selectedSearchFolderId
        }

        if ReachabilityListener.instance.currentStatus == .offline {
            await mailboxManager.searchThreadsOffline(
                searchFolder: frozenSearchFolder,
                filterFolderId: folderToSearch,
                searchFilters: searchFiltersOffline
            )
        } else {
            await tryOrDisplayError {
                let result = try await mailboxManager.searchThreads(
                    searchFolder: frozenSearchFolder,
                    filterFolderId: folderToSearch,
                    filter: filter,
                    searchFilter: searchFilters
                )

                resourceNext = result.resourceNext
            }
        }
        observeSearch()
    }

    func fetchNextPage() async {
        guard !isLoading, let resource = resourceNext else {
            return
        }

        isLoading = true
        await tryOrDisplayError {
            let threadResult = try await mailboxManager.searchThreads(
                searchFolder: frozenSearchFolder,
                from: resource,
                searchFilter: searchFilters
            )
            resourceNext = threadResult.resourceNext
        }
        isLoading = false
    }

    func loadNextPageIfNeeded(currentItem: Thread) {
        // Start loading next page when we reach the second-to-last item
        guard !frozenThreads.isEmpty else { return }
        let thresholdIndex = frozenThreads.index(frozenThreads.endIndex, offsetBy: -1)
        if frozenThreads.firstIndex(where: { $0.uid == currentItem.uid }) == thresholdIndex {
            Task {
                await fetchNextPage()
            }
        }
    }

    func addCurrentSearchTermToHistoryIfNeeded() {
        if searchValue.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 {
            Task {
                await mailboxManager.addToSearchHistory(value: searchValue)
            }
        }
    }

    func onTapCell(thread: Thread) {
        // Required by ThreadListable for direction detection but not used, we always go back in search
    }

    func refreshSearchIfNeeded(action: Action) {
        guard action.refreshSearchResult else { return }
        Task {
            // Need to wait 500 milliseconds before reloading
            try await Task.sleep(nanoseconds: 500_000_000)
            await fetchThreads()
        }
    }
}
