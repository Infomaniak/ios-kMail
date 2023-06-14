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

extension SearchViewModel {
    var searchFilters: [URLQueryItem] {
        var queryItems: [URLQueryItem] = []
        if !searchValue.isEmpty {
            if searchValue.hasPrefix("\"") && searchValue.hasSuffix("\"") {
                searchValueType = .contact
            }
            if searchValueType == .contact {
                queryItems.append(URLQueryItem(name: "sfrom",
                                               value: searchValue.replacingOccurrences(of: "\"", with: "")))
            } else {
                queryItems.append(URLQueryItem(name: "scontains", value: searchValue))
            }
        }
        queryItems.append(URLQueryItem(name: "severywhere",
                                       value: selectedFilters.contains(.folder) ? "0" : "1"))

        if selectedFilters.contains(.attachment) {
            queryItems.append(URLQueryItem(name: "sattachments", value: "yes"))
        }

        return queryItems
    }

    var filter: Filter {
        if selectedFilters.contains(.read) {
            return .seen
        } else if selectedFilters.contains(.unread) {
            return .unseen
        } else if selectedFilters.contains(.favorite) {
            return .starred
        }
        return .all
    }

    var searchFiltersOffline: [SearchCondition] {
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

    func unselect(filter: SearchFilter) {
        selectedFilters.removeAll {
            $0 == filter
        }
    }

    func select(filter: SearchFilter) {
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

    public var matomoName: String {
        return "\(rawValue)Filter"
    }
}
