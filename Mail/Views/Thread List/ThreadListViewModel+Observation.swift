/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import MailCore
import RealmSwift
import SwiftUI

extension ThreadListViewModel {
    private func threadResults() -> Results<Thread>? {
        guard let folder = frozenFolder.thaw() else {
            sectionsSubject.send([])
            return nil
        }

        let threadsSort = folder.threadsSort

        let threadResults: Results<Thread>
        if let predicate = filter.predicate {
            threadResults = folder.threads
                .where { $0.isMovedOutLocally == false }
                .filter(predicate + " OR uid == %@", selectedThreadOwner.selectedThread?.uid ?? "")
                .sorted(byKeyPath: threadsSort.propertyName, ascending: threadsSort.isAscending)
        } else {
            threadResults = folder.threads
                .where { $0.isMovedOutLocally == false }
                .sorted(byKeyPath: threadsSort.propertyName, ascending: threadsSort.isAscending)
        }

        return threadResults
    }

    // MARK: - Observe global changes

    func observeChanges() {
        stopObserveChanges()
        observationThreadToken = threadResults()?
            .observe(on: observeQueue) { [weak self] changes in
                guard let self else { return }

                switch changes {
                case .initial(let results):
                    let (filteredThreads, newSections) = mapSectionedResults(results: results.freezeIfNeeded())

                    resetFilterIfNeeded(filteredThreads: filteredThreads)

                    DispatchQueue.main.sync {
                        self.filteredThreads = filteredThreads
                    }
                    sectionsSubject.send(newSections)
                case .update(let results, _, _, _):
                    updateThreadResults(results: results.freezeIfNeeded())
                case .error:
                    break
                }

                // We only apply the first update when in "unread" mode
                if filter == .unseen {
                    stopObserveChanges()
                }
            }
    }

    func stopObserveChanges() {
        observationThreadToken?.invalidate()
        observationLastUpdateToken?.invalidate()
    }

    private func mapSectionedResults(results: Results<Thread>) -> (threads: [Thread], sections: [DateSection]) {
        let threadsSort = frozenFolder.threadsSort

        let results = Dictionary(grouping: results.freezeIfNeeded()) { $0.sectionDate }
            .sorted {
                guard let firstThread = $0.value.first, let secondThread = $1.value.first else { return false }

                guard let firstDate = threadsSort.getReferenceDate(from: firstThread),
                      let secondDate = threadsSort.getReferenceDate(from: secondThread) else { return false }

                if threadsSort.isAscending {
                    return firstDate < secondDate
                } else {
                    return firstDate > secondDate
                }
            }

        var threads = [Thread]()
        let sections = results.map {
            let sectionThreads = Array($0.value)
            threads.append(contentsOf: sectionThreads)
            return DateSection(sectionKey: $0.key, threads: sectionThreads)
        }

        return (threads: threads, sections: sections)
    }

    private func updateThreadResults(results: Results<Thread>) {
        let oldFilteredThreads = filteredThreads
        let (filteredThreads, newSections) = mapSectionedResults(results: results)

        resetFilterIfNeeded(filteredThreads: filteredThreads)

        DispatchQueue.main.sync {
            self.nextThreadIfNeeded(oldThreads: oldFilteredThreads, newThreads: filteredThreads)
            self.filteredThreads = filteredThreads
            if self.filter != .all,
               filteredThreads.count == 1,
               !self.filter.accepts(thread: filteredThreads[0]) {
                self.filter = .all
            }

            sectionsSubject.send(newSections)
        }
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
        let allThreads = mailboxManager.fetchResults(ofType: Thread.self) { partial in
            partial
                .filter(containAnyOf)
                .sorted(by: \.date, ascending: false)
        }

        observeFilteredThreadsToken = allThreads.observe(on: observeQueue) { [weak self] changes in
            guard let self else { return }

            switch changes {
            case .initial:
                break
            case .update(let results, _, _, _):
                updateThreadResults(results: results.freezeIfNeeded())
            case .error:
                break
            }
        }
    }

    func stopObserveFilteredThreads() {
        observeFilteredThreadsToken?.invalidate()
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
                // Disable filter if we have no unread emails left
                guard unreadCount == 0 && filterUnreadOn else { return }
                Task { @MainActor in
                    withAnimation {
                        self.filterUnreadOn = false
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
