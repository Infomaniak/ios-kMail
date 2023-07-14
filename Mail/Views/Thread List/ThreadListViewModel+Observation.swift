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
import RealmSwift
import SwiftUI

extension ThreadListViewModel {
    private func threadResults() -> Results<Thread>? {
        guard let folder = folder.thaw() else {
            sections = []
            return nil
        }

        let threadResults: Results<Thread>
        if let predicate = filter.predicate {
            threadResults = folder.threads
                .filter(predicate + " OR uid == %@", selectedThread?.uid ?? "")
                .sorted(by: \.date, ascending: false)
        } else {
            threadResults = folder.threads.sorted(by: \.date, ascending: false)
        }

        return threadResults
    }

    // MARK: - Observe global changes

    func observeChanges(animateInitialThreadChanges: Bool = false) {
        stopObserveChanges()

        observationThreadToken = threadResults()?.observe(on: observeQueue) { [weak self] changes in
            guard let self else {
                return
            }

            switch changes {
            case .initial(let results):
                let filteredThreads = Array(results.freezeIfNeeded())
                guard let newSections = sortThreadsIntoSections(threads: filteredThreads) else { return }

                DispatchQueue.main.sync {
                    self.filteredThreads = filteredThreads
                    withAnimation(animateInitialThreadChanges ? .default : nil) {
                        self.sections = newSections
                    }
                }
            case .update(let results, _, _, _):
                let filteredThreads = Array(results.freezeIfNeeded())
                guard let newSections = sortThreadsIntoSections(threads: filteredThreads) else { return }

                DispatchQueue.main.sync {
                    self.nextThreadIfNeeded(from: filteredThreads)
                    self.filteredThreads = filteredThreads
                    if self.filter != .all,
                       filteredThreads.count == 1,
                       !self.filter.accepts(thread: filteredThreads[0]) {
                        self.filter = .all
                    }
                    withAnimation {
                        self.sections = newSections
                    }
                }
            case .error:
                break
            }

            // We only apply the first update when in "unread" mode
            if filter == .unseen {
                stopObserveChanges()
            }
        }
        observationLastUpdateToken = folder.observe(keyPaths: [\Folder.lastUpdate], on: observeQueue) { [weak self] changes in
            switch changes {
            case .change(let folder, _):
                let lastUpdate = folder.freezeIfNeeded().lastUpdate
                Task {
                    await MainActor.run {
                        withAnimation {
                            self?.lastUpdate = lastUpdate
                        }
                    }
                }
            default:
                break
            }
        }
    }

    func stopObserveChanges() {
        observationThreadToken?.invalidate()
        observationLastUpdateToken?.invalidate()
    }

    // MARK: - Observe filtered results

    static let containAnyOfUIDs = "uid IN %@"

    /// Observe filtered threads, when global observation is disabled.
    func observeFilteredResults() {
        stopObserveFilteredThreads()

        let allThreadsUIDs = threadResults()?.reduce([String]()) { partialResult, thread in
            partialResult + [thread.uid]
        }

        guard let allThreadsUIDs else {
            return
        }

        let containAnyOf = NSPredicate(format: Self.containAnyOfUIDs, allThreadsUIDs)
        let realm = mailboxManager.getRealm()
        let allThreads = realm.objects(Thread.self).filter(containAnyOf)

        observeFilteredThreadsToken = allThreads.observe(on: observeQueue) { [weak self] changes in
            guard let self else {
                return
            }

            switch changes {
            case .initial:
                break
            case .update(let all, _, _, let modificationIndexes):
                refreshInFilterMode(all: all, changes: modificationIndexes)
            case .error:
                break
            }
        }
    }

    func stopObserveFilteredThreads() {
        observeFilteredThreadsToken?.invalidate()
    }

    /// Update filtered threads on observation change.
    private func refreshInFilterMode(all: Results<Thread>, changes: [Int]) {
        for index in changes {
            let updatedThread = all[index]
            let uid = updatedThread.uid

            let threadToUpdate: Thread? = sections.reduce(nil as Thread?) { partialResult, section in
                partialResult ?? section.threads.first { $0.uid == uid }
            }

            let sectionToUpdate = sections.first { section in
                section.threads.contains { $0.uid == uid }
            }

            guard let threadToUpdate,
                  let sectionToUpdate else {
                continue
            }

            let threadToUpdateIndex = sectionToUpdate.threads.firstIndex(of: threadToUpdate)
            guard let threadToUpdateIndex else {
                continue
            }

            sectionToUpdate.threads[threadToUpdateIndex] = updatedThread.freeze()

            Task {
                await MainActor.run {
                    objectWillChange.send()
                }
            }
        }
    }

    // MARK: - Observe unread count

    /// Observe the unread count to disable filtering when it reaches 0
    func observeUnreadCount() {
        stopObserveUnread()

        observationUnreadToken = threadResults()?.observe(on: observeQueue) { [weak self] changes in
            guard let self else {
                return
            }

            switch changes {
            case .initial(let all), .update(let all, _, _, _):
                let unreadCount = all.where { $0.unseenMessages > 0 }.count
                Task {
                    await MainActor.run {
                        self.unreadCount = unreadCount
                    }
                }

            case .error:
                break
            }
        }
    }

    func stopObserveUnread() {
        observationUnreadToken?.invalidate()
    }
}
