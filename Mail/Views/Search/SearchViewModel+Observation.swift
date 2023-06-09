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
    /// Observe changes on the current folder
    func observeChanges() {
        stopObserveChanges()

        guard let folder = searchFolder.thaw() else {
            threads = []
            return
        }

        let threadResults = folder.threads.sorted(by: \.date, ascending: false)
        observationSearchThreadToken = threadResults.observe(on: observeQueue) { [weak self] changes in
            guard let self = self else {
                return
            }

            switch changes {
            case .initial(let results):
                let results = Array(results.freezeIfNeeded())
                Task {
                    await MainActor.run {
                        withAnimation {
                            self.threads = results
                        }
                        self.isLoading = false
                    }
                }

            case .update(let results, _, _, let modificationIndexes):
                let results = Array(results.freezeIfNeeded())
                refreshInUnreadFilterMode(all: results, changes: modificationIndexes)

            case .error:
                break
            }
        }
    }

    func stopObserveChanges() {
        observationSearchThreadToken?.invalidate()
    }

    /// Update filtered threads on observation change.
    private func refreshInUnreadFilterMode(all: [Thread], changes: [Int]) {
        Task.detached {
            for index in changes {
                guard let updatedThread = all[safe: index] else {
                    continue
                }

                // Swap the updated thread at index
                await MainActor.run {
                    withAnimation {
                        self.threads[index] = updatedThread
                    }
                }
            }

            // finish with changing the loading state
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}
