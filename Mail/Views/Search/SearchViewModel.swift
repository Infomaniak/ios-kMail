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
import InfomaniakCore
import InfomaniakCoreUI
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

@MainActor class SearchViewModel: ObservableObject {
    let mailboxManager: MailboxManager

    public let filters: [SearchFilter] = [.read, .unread, .favorite, .attachment, .folder]
    @Published var selectedFilters: [SearchFilter] = [] {
        willSet {
            // cancel current running tasks
            stopObserveSearch()
            currentSearchTask?.cancel()
            threads = []
        }
    }

    var searchValueType: SearchFieldValueType = .threadsAndContacts
    @Published var searchValue = ""
    var searchState: SearchState {
        if selectedFilters.isEmpty && searchValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .history
        } else if (threads.isEmpty && !isLoading) && contacts.isEmpty {
            return .noResults
        } else {
            return .results
        }
    }

    @Published var folderList: [Folder]
    @Published var frozenRealFolder: Folder
    var lastSearchFolderId: String?

    /// Token to observe the search itself
    var observationSearchThreadToken: NotificationToken?

    /// Token to observe the fetched search results changes
    var observationSearchResultsChangesToken: NotificationToken?

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

    var selectedThread: Thread?

    @Published var threads: [Thread] = []
    @Published var contacts: [Recipient] = []
    @Published var isLoading = false

    @LazyInjectService var matomo: MatomoUtils

    let searchFolder: Folder
    var resourceNext: String?
    var lastSearch = ""
    var searchFieldObservation: AnyCancellable?
    var currentSearchTask: Task<Void, Never>?
    let observeQueue = DispatchQueue(label: "com.infomaniak.observation.SearchViewModel", qos: .userInteractive)

    init(mailboxManager: MailboxManager, folder: Folder) {
        self.mailboxManager = mailboxManager

        frozenRealFolder = folder.freezeIfNeeded()
        searchFolder = mailboxManager.initSearchFolder().freezeIfNeeded()
        folderList = mailboxManager.getFolders()

        searchFieldObservation = $searchValue
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { [weak self] newValue in
                guard let self,
                      lastSearch.trimmingCharacters(in: .whitespacesAndNewlines) != newValue
                      .trimmingCharacters(in: .whitespacesAndNewlines) else {
                    return
                }
                lastSearch = newValue
                searchValueType = .threadsAndContacts
                performSearch()
            }
    }

    func updateContactSuggestion() {
        let autocompleteContacts = mailboxManager.contactManager.contacts(matching: searchValue)
        var autocompleteRecipients = autocompleteContacts.map { Recipient(email: $0.email, name: $0.name) }
        // Append typed email
        if Constants.isEmailAddress(searchValue) && !contacts
            .contains(where: { $0.email.caseInsensitiveCompare(searchValue) == .orderedSame }) {
            autocompleteRecipients.append(Recipient(email: searchValue, name: ""))
        }
        let contactRange: Range<Int> = 0 ..< min(autocompleteRecipients.count, Constants.contactSuggestionLimit)
        withAnimation {
            contacts = Array(autocompleteRecipients[contactRange])
        }
    }

    func fetchThreads() async {
        guard !isLoading else {
            return
        }

        isLoading = true
        stopObserveSearch()
        threads = []

        var folderToSearch = frozenRealFolder.remoteId

        if selectedFilters.contains(.folder) {
            folderToSearch = selectedSearchFolderId
            lastSearchFolderId = selectedSearchFolderId
        }

        if ReachabilityListener.instance.currentStatus == .offline {
            await mailboxManager.searchThreadsOffline(
                searchFolder: searchFolder,
                filterFolderId: folderToSearch,
                searchFilters: searchFiltersOffline
            )
        } else {
            await tryOrDisplayError {
                let result = try await mailboxManager.searchThreads(
                    searchFolder: searchFolder,
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
                searchFolder: searchFolder.freeze(),
                from: resource,
                searchFilter: searchFilters
            )
            resourceNext = threadResult.resourceNext
        }
        isLoading = false
    }

    func loadNextPageIfNeeded(currentItem: Thread) {
        // Start loading next page when we reach the second-to-last item
        guard !threads.isEmpty else { return }
        let thresholdIndex = threads.index(threads.endIndex, offsetBy: -1)
        if threads.firstIndex(where: { $0.uid == currentItem.uid }) == thresholdIndex {
            Task {
                await fetchNextPage()
            }
        }
    }

    func addToHistoryIfNeeded() {
        if searchValue.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 {
            Task {
                await mailboxManager.addToSearchHistory(value: searchValue)
            }
        }
    }
}
