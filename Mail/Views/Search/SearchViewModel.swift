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
import MailCore
import MailResources

@MainActor class SearchViewModel: ObservableObject {
    var mailboxManager: MailboxManager

    @Published public var filters: [SearchFilter]
    @Published public var selectedFilters: [SearchFilter] = []
    @Published public var searchValue = ""

    @Published public var threads: [Thread] = []

    public var folder: Folder?
    @Published var isLoadingPage = false

    private var resourceNext: String?

    // TODO: - IMPORTANT
//    Si connexion -> Recherche depui s call API uniquement
//    Si pas de connextion -> Recherche depuis Realm uniquement

    init(folder: Folder?) {
        mailboxManager = AccountManager.instance.currentMailboxManager!
        self.folder = folder

        filters = [
            .read,
            .unread,
            .favorite,
            .attachment,
            .folder
        ]
    }

    func updateSelection(filter: SearchFilter) {
        if selectedFilters.contains(filter) {
            unselect(filter: filter)
        } else {
            select(filter: filter)
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
        guard !isLoadingPage else {
            return
        }

        isLoadingPage = true

        var filter: Filter = .all

        var searchFilters: [URLQueryItem] = []

        searchFilters.append(URLQueryItem(name: "scontains", value: searchValue))

        for selected in selectedFilters {
            switch selected {
            case .read:
                filter = .seen
            case .unread:
                filter = .unseen
            case .favorite:
                filter = .starred
            case .attachment:
                return
//                searchFilters.append(URLQueryItem(name: "sattachment", value: <#T##String?#>))
            case .folder:
                return
            }
        }

        await tryOrDisplayError {
            guard let folder = folder else { return }

            let threadResult = try await mailboxManager.apiFetcher.threads(
                mailbox: mailboxManager.mailbox,
                folder: folder,
                filter: filter,
                searchFilter: searchFilters
            )
            threads.append(contentsOf: threadResult.threads ?? [])
            resourceNext = threadResult.resourceNext
        }
        isLoadingPage = false
        mailboxManager.draftOffline()
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
