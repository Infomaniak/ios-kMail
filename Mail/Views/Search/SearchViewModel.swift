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

@MainActor class SearchViewModel: ObservableObject {
    var mailboxManager: MailboxManager

    @Published public var filters: [SearchFilter]
    @Published public var selectedFilters: [SearchFilter] = []
    @Published public var searchValue = ""
    @Published public var selectedFolderId = ""

    @Published public var threads: [Thread] = []

    public var searchFolder: Folder

    public var folderId: String?
    @Published var isLoadingPage = false

    private var resourceNext: String?
    private var observationSearchThreadToken: NotificationToken?

    // TODO: - IMPORTANT
//    Si connexion -> Recherche depui s call API uniquement
//    Si pas de connextion -> Recherche depuis Realm uniquement

    var observeSearch: Bool {
        didSet {
            if observeSearch {
                observeChanges()
            } else {
                observationSearchThreadToken?.invalidate()
            }
        }
    }

    init(folderId: String?) {
        mailboxManager = AccountManager.instance.currentMailboxManager!
        self.folderId = folderId

        searchFolder = mailboxManager.initSearchFolder()

        filters = [
            .read,
            .unread,
            .favorite,
            .attachment,
            .folder
        ]

        observeSearch = true
    }

    public var folderFilterTitle: String {
        if selectedFilters.contains(.folder) {}
        return SearchFilter.folder.title
    }

    func updateSelection(filter: SearchFilter) {
        if selectedFilters.contains(filter) {
            unselect(filter: filter)
        } else {
            select(filter: filter)
        }
    }

    func updateSelection(filter: SearchFilter, add: Bool) {
        if add && !selectedFilters.contains(filter) {
            select(filter: filter)
        } else if !add && selectedFilters.contains(filter) {
            unselect(filter: filter)
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
        case .attachment:
            return
        case .folder:
            return
        }
    }

    func fetchThreads() async {
        guard !isLoadingPage, let folderId = folderId else {
            return
        }

        isLoadingPage = true

        var filter: Filter = .all
        var folderToSearch: String = folderId

        var searchFilters: [URLQueryItem] = []
        if !searchValue.isEmpty {
            searchFilters.append(URLQueryItem(name: "scontains", value: searchValue))
        }
        if !selectedFolderId.isEmpty && !selectedFilters.contains(.folder) {
            selectedFilters.append(.folder)
        }

        for selected in selectedFilters {
            switch selected {
            case .read:
                filter = .seen
            case .unread:
                filter = .unseen
            case .favorite:
                filter = .starred
            case .attachment:
                searchFilters.append(URLQueryItem(name: "sattachment", value: "yes"))
            case .folder:
                searchFilters.append(URLQueryItem(name: "severywhere", value: "0"))
                folderToSearch = selectedFolderId
            }
        }

        await tryOrDisplayError {
            let result = try await mailboxManager.searchThreads(
                filterFolderId: folderToSearch,
                filter: filter,
                searchFilter: searchFilters
            )

            resourceNext = result.resourceNext
        }
        isLoadingPage = false
    }

    func fetchNextPage() async {
        guard !isLoadingPage, let resource = resourceNext else {
            return
        }

        isLoadingPage = true

        await tryOrDisplayError {
            let threadResult = try await mailboxManager.apiFetcher.threads(from: resource)
            threads.append(contentsOf: threadResult.threads ?? [])
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
