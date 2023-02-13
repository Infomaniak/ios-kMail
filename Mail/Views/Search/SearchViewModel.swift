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
import MailCore
import MailResources
import RealmSwift
import SwiftUI

enum SearchFieldValueType: String {
    case contact
    case threads
    case threadsAndContacts
}

enum SearchState {
    case history
    case noHistory
    case results
    case noResults
}

@MainActor class SearchViewModel: ObservableObject {
    let mailboxManager: MailboxManager
    @Published var searchHistory: SearchHistory

    public let filters: [SearchFilter] = [.read, .unread, .favorite, .attachment, .folder]
    @Published var selectedFilters: [SearchFilter] = []
    var searchValueType: SearchFieldValueType = .threadsAndContacts
    @Published var searchValue = ""
    var searchState: SearchState {
        if selectedFilters.isEmpty && searchValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return searchHistory.history.isEmpty ? .noHistory : .history
        } else if (threads.isEmpty && !isLoading) && contacts.isEmpty {
            return .noResults
        } else {
            return .results
        }
    }

    @Published var folderList: [Folder]
    @Published var realFolder: Folder?
    var lastSearchFolderId: String?
    var observationSearchThreadToken: NotificationToken?
    @Published var selectedSearchFolderId = "" {
        didSet {
            if selectedSearchFolderId.isEmpty {
                selectedFilters.removeAll { $0 == .folder }
            } else if !selectedFilters.contains(.folder) {
                selectedFilters.append(.folder)
            }
            Task {
                await fetchThreads()
            }
        }
    }

    var selectedThread: Thread?

    @Published var threads: [Thread] = []
    @Published var contacts: [Recipient] = []
    @Published var isLoading = false

    private let searchFolder: Folder
    private var resourceNext: String?
    private var lastSearch = ""
    private var searchFieldObservation: AnyCancellable?

    init(mailboxManager: MailboxManager, folder: Folder?) {
        self.mailboxManager = mailboxManager
        searchHistory = mailboxManager.searchHistory()
        realFolder = folder

        searchFolder = mailboxManager.initSearchFolder()

        folderList = mailboxManager.getFolders()

        searchFieldObservation = $searchValue
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { [weak self] newValue in
                guard self?.lastSearch.trimmingCharacters(in: .whitespacesAndNewlines) != newValue
                    .trimmingCharacters(in: .whitespacesAndNewlines) else {
                    return
                }
                self?.lastSearch = newValue
                self?.searchValueType = .threadsAndContacts
                self?.performSearch()
            }
        observeChanges()
    }

    func initSearch() {
        clearSearch()
        selectedFilters = []
    }

    func clearSearch() {
        Task {
            searchValueType = .threadsAndContacts
            searchValue = ""
            threads = []
            contacts = []
            isLoading = false
        }
    }

    func searchThreadsForCurrentValue() {
        searchValueType = .threads
        performSearch()
    }

    func searchFilter(_ filter: SearchFilter) {
        withAnimation {
            if selectedFilters.contains(filter) {
                unselect(filter: filter)
            } else {
                searchValueType = .threads
                select(filter: filter)
            }
        }

        performSearch()
    }

    func searchThreadsForContact(_ contact: Recipient) {
        searchValueType = .contact
        searchValue = "\"" + contact.email + "\""
    }

    private func performSearch() {
        if searchValueType == .threadsAndContacts {
            updateContactSuggestion()
        } else {
            contacts = []
        }

        Task {
            await fetchThreads()
        }
    }

    private var searchFilters: [URLQueryItem] {
        var queryItems: [URLQueryItem] = []
        if !searchValue.isEmpty {
            if searchValue.hasPrefix("\"") && searchValue.hasSuffix("\"") {
                searchValueType = .contact
            }
            if searchValueType == .contact {
                queryItems.append(URLQueryItem(name: "sfrom", value: searchValue.replacingOccurrences(of: "\"", with: "")))
            } else {
                queryItems.append(URLQueryItem(name: "scontains", value: searchValue))
            }
        }
        queryItems.append(URLQueryItem(name: "severywhere", value: selectedFilters.contains(.folder) ? "0" : "1"))

        if selectedFilters.contains(.attachment) {
            queryItems.append(URLQueryItem(name: "sattachments", value: "yes"))
        }

        return queryItems
    }

    private var filter: Filter {
        if selectedFilters.contains(.read) {
            return .seen
        } else if selectedFilters.contains(.unread) {
            return .unseen
        } else if selectedFilters.contains(.favorite) {
            return .starred
        }
        return .all
    }

    private var searchFiltersOffline: [SearchCondition] {
        var queryItems: [SearchCondition] = []
        queryItems.append(SearchCondition.filter(filter))

        if !searchValue.isEmpty {
            if searchValue.hasPrefix("\"") && searchValue.hasSuffix("\"") {
                searchValueType = .contact
            }
            if searchValueType == .contact {
                queryItems.append(SearchCondition.from(searchValue.replacingOccurrences(of: "\"", with: "")))
            } else {
                queryItems.append(SearchCondition.contains(searchValue))
            }
        }
        queryItems.append(SearchCondition.everywhere(!selectedFilters.contains(.folder)))
        queryItems.append(SearchCondition.attachments(selectedFilters.contains(.attachment)))

        return queryItems
    }

    private func updateContactSuggestion() {
        let contactManager = AccountManager.instance.currentContactManager
        let autocompleteContacts = contactManager?.contacts(matching: searchValue) ?? []
        var autocompleteRecipients = autocompleteContacts.map { Recipient(email: $0.email, name: $0.name) }
        // Append typed email
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", Constants.mailRegex)
        if emailPredicate.evaluate(with: searchValue) && !contacts
            .contains(where: { $0.email.caseInsensitiveCompare(searchValue) == .orderedSame }) {
            autocompleteRecipients.append(Recipient(email: searchValue, name: ""))
        }
        let contactRange: Range<Int> = 0 ..< min(autocompleteRecipients.count, Constants.contactSuggestionLimit)
        withAnimation {
            contacts = Array(autocompleteRecipients[contactRange])
        }
    }

    private func unselect(filter: SearchFilter) {
        selectedFilters.removeAll {
            $0 == filter
        }
    }

    private func select(filter: SearchFilter) {
        selectedFilters.append(filter)
        switch filter {
        case .read:
            selectedFilters.removeAll {
                $0 == .unread || $0 == .favorite
            }
        case .unread:
            selectedFilters.removeAll {
                $0 == .read || $0 == .favorite
            }
        case .favorite:
            selectedFilters.removeAll {
                $0 == .read || $0 == .unread
            }
        default:
            return
        }
    }

    func fetchThreads() async {
        guard !isLoading, let realFolder = realFolder else {
            return
        }

        isLoading = true

        let frozenSearchFolder = searchFolder.freeze()
        observationSearchThreadToken?.invalidate()
        threads = []

        var folderToSearch = realFolder.id

        if selectedFilters.contains(.folder) {
            folderToSearch = selectedSearchFolderId
            lastSearchFolderId = selectedSearchFolderId
        }

        if ReachabilityListener.instance.currentStatus == .offline {
            // Search offline
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
        observeChanges()

        if searchValue.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 {
            searchHistory = await mailboxManager.update(searchHistory: searchHistory, with: searchValue)
        }
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

    private func observeChanges() {
        observationSearchThreadToken?.invalidate()
        if let folder = searchFolder.thaw() {
            let threadResults = folder.threads.sorted(by: \.date, ascending: false)
            observationSearchThreadToken = threadResults.observe(on: .main) { [weak self] changes in
                switch changes {
                case let .initial(results):
                    self?.threads = Array(results.freezeIfNeeded())
                case let .update(results, _, _, _):
                    withAnimation {
                        self?.threads = Array(results.freezeIfNeeded())
                    }
                case .error:
                    break
                }
                self?.isLoading = false
            }

        } else {
            threads = []
        }
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
}

public enum SearchFilter: String, Identifiable {
    public var id: Self { self }

    case read
    case unread
    case favorite
    case attachment
    case folder

    public var title: String {
        switch self {
        case .read:
            return MailResourcesStrings.Localizable.searchFilterRead
        case .unread:
            return MailResourcesStrings.Localizable.searchFilterUnread
        case .favorite:
            return MailResourcesStrings.Localizable.favoritesFolder
        case .attachment:
            return MailResourcesStrings.Localizable.searchFilterAttachment
        case .folder:
            return MailResourcesStrings.Localizable.searchFilterFolder
        }
    }
}
