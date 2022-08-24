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
import MailCore
import MailResources
import RealmSwift
import SwiftUI

enum SearchFieldValueType: String {
    case contact
    case search
}

@MainActor class SearchViewModel: ObservableObject {
    var mailboxManager: MailboxManager
    @Published var searchHistory: SearchHistory

    @Published public var filters: [SearchFilter]
    @Published public var selectedFilters: [SearchFilter] = []
    @Published public var searchValueType: SearchFieldValueType = .search
    @Published public var searchValue = "" {
        didSet {
            if searchValueType == .search {
                updateContactSuggestion()
            } else {
                searchValueType = .search
            }
        }
    }

    @Published public var folderList: [Folder]
    @Published public var realFolder: Folder?
    public var lastSearchFolderId: String?
    @Published public var selectedSearchFolderId = "" {
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

    @Published var selectedThread: Thread?

    @Published public var threads: [Thread] = []
    @Published public var contacts: [Recipient] = []

    @Published public var searchFolder: Folder

    @Published var isLoadingPage = false

    private var resourceNext: String?
    private var observationSearchThreadToken: NotificationToken?

    // TODO: - IMPORTANT
//    Si connexion -> Recherche depuis call API uniquement
//    Si pas de connexion -> Recherche depuis Realm uniquement

    var observeSearch: Bool {
        didSet {
            if observeSearch {
                observeChanges()
            } else {
                observationSearchThreadToken?.invalidate()
            }
        }
    }

    init(mailboxManager: MailboxManager, folder: Folder?) {
        self.mailboxManager = mailboxManager

        searchHistory = mailboxManager.searchHistory()
        realFolder = folder

        searchFolder = mailboxManager.initSearchFolder()

        filters = [
            .read,
            .unread,
            .favorite,
            .attachment,
            .folder
        ]

        observeSearch = true
        folderList = mailboxManager.getFolders()
    }

    func initSearch() {
        clearSearchValue()
        selectedFilters = []
    }

    func clearSearchValue() {
        searchFolder = mailboxManager.cleanSearchFolder()
        searchValue = ""
        threads = []
        contacts = []
    }

    private var searchFilters: [URLQueryItem] {
        var queryItems: [URLQueryItem] = []
        if !searchValue.isEmpty {
            if searchValueType == .contact {
                queryItems.append(URLQueryItem(name: "sfrom", value: searchValue))
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
        withAnimation {
            contacts = autocompleteRecipients
        }
    }

    func updateSelection(filter: SearchFilter) {
        withAnimation {
            if selectedFilters.contains(filter) {
                unselect(filter: filter)
            } else {
                select(filter: filter)
            }
        }

        Task {
            await fetchThreads()
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
        guard !isLoadingPage, let realFolder = realFolder else {
            return
        }

        searchFolder = mailboxManager.cleanSearchFolder()
        observeSearch = true

        isLoadingPage = true

        var folderToSearch = realFolder.id

        if selectedFilters.contains(.folder) {
            folderToSearch = selectedSearchFolderId
            lastSearchFolderId = selectedSearchFolderId
        }

        await tryOrDisplayError {
            let result = try await mailboxManager.searchThreads(
                searchFolder: searchFolder,
                filterFolderId: folderToSearch,
                filter: filter,
                searchFilter: searchFilters
            )

            resourceNext = result.resourceNext

            if !searchValue.isEmpty {
                searchHistory = mailboxManager.update(searchHistory: searchHistory, with: searchValue)
            }
        }
        isLoadingPage = false
    }

    func fetchNextPage() async {
        guard !isLoadingPage, let resource = resourceNext else {
            return
        }

        isLoadingPage = true

        await tryOrDisplayError {
            let threadResult = try await mailboxManager.searchThreads(
                searchFolder: searchFolder,
                from: resource,
                searchFilter: searchFilters
            )
            resourceNext = threadResult.resourceNext
        }
        isLoadingPage = false
    }

    func observeChanges() {
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
