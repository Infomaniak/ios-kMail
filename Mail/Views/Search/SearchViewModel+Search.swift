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

import MailCore
import SwiftUI

extension SearchViewModel {
    func searchFilter(_ filter: SearchFilter) {
        withAnimation {
            if selectedFilters.contains(filter) {
                unselect(filter: filter)
            } else {
                matomo.track(eventWithCategory: .search, name: filter.matomoName)
                searchValueType = .threads
                select(filter: filter)
            }
        }

        performSearch()
    }

    func clearSearch() {
        searchValueType = .threadsAndContacts
        searchValue = ""
        frozenThreads = []
        frozenContacts = []
        isLoading = false
    }

    func searchThreadsForCurrentValue() {
        searchValueType = .threads
        performSearch()
    }

    func searchThreadsForContact(_ contact: Recipient) {
        searchValueType = .contact
        searchValue = "\"" + contact.email + "\""
    }

    func performSearch() {
        if searchValueType == .threadsAndContacts {
            updateContactSuggestion()
        } else {
            frozenContacts = []
        }

        currentSearchTask?.cancel()
        currentSearchTask = Task {
            await fetchThreads()
        }
    }
}
