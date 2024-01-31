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

import SwiftUI

extension SearchViewModel {
    // MARK: Current folder Search observation

    /// Observe changes on the current folder
    func observeSearch() {
        stopObserveSearch()
        stopObserveSearchResultsChanges()

        guard let liveFolder = frozenSearchFolder.thaw() else {
            frozenThreads = []
            return
        }

        let threadResults = liveFolder.threads.sorted(by: \.date, ascending: false)
        observationSearchThreadToken = threadResults.observe(on: .main) { [weak self] changes in
            guard let self else {
                return
            }

            switch changes {
            case .initial(let results):
                let frozenResults = Array(results.freezeIfNeeded())
                Task {
                    await MainActor.run {
                        withAnimation {
                            self.frozenThreads = frozenResults
                        }
                        self.isLoading = false

                        // start observing loaded results
                        self.observeSearchResultsChanges()
                    }
                }

            default:
                break
            }
        }
    }

    func stopObserveSearch() {
        observationSearchThreadToken?.invalidate()
    }

    // MARK: Search Results Changes observation

    static let containAnyOfUIDs = "uid IN %@"

    func observeSearchResultsChanges() {
        stopObserveSearchResultsChanges()

        let allThreadsUIDs = frozenThreads.map(\.uid)
        let containAnyOf = NSPredicate(format: Self.containAnyOfUIDs, allThreadsUIDs)
        let realm = mailboxManager.getRealm()
        let allThreads = realm.objects(Thread.self).filter(containAnyOf)

        observationSearchResultsChangesToken = allThreads.observe(on: observeQueue) { [weak self] changes in
            guard let self else {
                return
            }

            switch changes {
            case .update(let results, _, _, let modificationIndexes):
                let frozenResults = Array(results.freezeIfNeeded())
                refreshObservedSearchResults(allFrozen: frozenResults, changes: modificationIndexes)

            default:
                break
            }
        }
    }

    func stopObserveSearchResultsChanges() {
        observationSearchResultsChangesToken?.invalidate()
    }

    /// Update search result threads on observation change.
    private func refreshObservedSearchResults(allFrozen: [Thread], changes: [Int]) {
        Task {
            for index in changes {
                guard let updatedThread = allFrozen[safe: index] else {
                    continue
                }

                // Swap the updated thread at index
                await MainActor.run {
                    withAnimation {
                        self.frozenThreads[index] = updatedThread
                    }
                }
            }

            // finish by changing the loading state
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}
