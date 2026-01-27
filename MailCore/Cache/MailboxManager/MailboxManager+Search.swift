/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

import Foundation
import InfomaniakCore
import InfomaniakCoreDB
import InfomaniakDI
import RealmSwift

// MARK: - Search

public extension MailboxManager {
    func initSearchFolder() -> Folder {
        let searchFolder = Folder(
            remoteId: Constants.searchFolderId,
            path: "",
            name: "",
            isFavorite: false,
            separator: "/",
            children: [],
            toolType: .search
        )

        try? writeTransaction { writableRealm in
            writableRealm.add(searchFolder, update: .modified)
        }

        return searchFolder
    }

    func clearSearchResults(searchFolder: Folder, writableRealm: Realm) {
        writableRealm.delete(writableRealm.objects(Message.self).where { $0.fromSearch == true })
        writableRealm.delete(writableRealm.objects(Thread.self).where { $0.fromSearch == true })
        searchFolder.threads.removeAll()
    }

    func clearSearchResults() async {
        try? writeTransaction { writableRealm in
            guard let searchFolder = writableRealm.objects(Folder.self)
                .where({ $0.remoteId == Constants.searchFolderId })
                .first else {
                return
            }

            self.clearSearchResults(searchFolder: searchFolder, writableRealm: writableRealm)
        }
    }

    func searchThreads(searchFolder: Folder?, filterFolderId: String, filter: Filter = .all,
                       searchFilter: [URLQueryItem] = []) async throws -> ThreadResult {
        let threadResult = try await apiFetcher.threads(
            mailbox: mailbox,
            folderId: filterFolderId,
            filter: filter,
            searchFilter: searchFilter,
            isDraftFolder: false
        )

        await prepareAndSaveSearchThreads(threadResult: threadResult, searchFolder: searchFolder)

        return threadResult
    }

    func searchThreads(searchFolder: Folder?, from resource: String,
                       searchFilter: [URLQueryItem] = []) async throws -> ThreadResult {
        let threadResult = try await apiFetcher.threads(from: resource, searchFilter: searchFilter)

        await prepareAndSaveSearchThreads(threadResult: threadResult, searchFolder: searchFolder)

        return threadResult
    }

    private func prepareAndSaveSearchThreads(threadResult: ThreadResult, searchFolder: Folder?) async {
        for thread in threadResult.threads ?? [] {
            thread.makeFromSearch(using: self)

            for message in thread.messages {
                guard fetchObject(ofType: Message.self, forPrimaryKey: message.uid) == nil else {
                    continue
                }
                message.fromSearch = true
            }
        }

        if let searchFolder {
            await saveSearchThreads(result: threadResult, searchFolder: searchFolder)
        }
    }

    func searchThreadsOffline(searchFolder: Folder?, filterFolderId: String,
                              searchFilters: [SearchCondition]) async {
        @InjectService var featureAvailableProvider: FeatureAvailableProvider
        try? writeTransaction { writableRealm in
            guard let searchFolder = searchFolder?.fresh(using: writableRealm) else {
                self.logError(.missingFolder)
                return
            }

            self.clearSearchResults(searchFolder: searchFolder, writableRealm: writableRealm)

            var predicates: [NSPredicate] = []
            if featureAvailableProvider.isAvailable(.emojiReaction) && UserDefaults.shared.threadMode == .conversation {
                predicates.append(NSPredicate(format: "emojiReaction = nil"))
            }
            for searchFilter in searchFilters {
                switch searchFilter {
                case .filter(let filter):
                    switch filter {
                    case .seen:
                        predicates.append(NSPredicate(format: "seen = true"))
                    case .unseen:
                        predicates.append(NSPredicate(format: "seen = false"))
                    case .starred:
                        predicates.append(NSPredicate(format: "flagged = true"))
                    case .unstarred:
                        predicates.append(NSPredicate(format: "flagged = false"))
                    default:
                        break
                    }
                case .from(let from):
                    predicates.append(NSPredicate(format: "ANY from.email = %@", from))
                case .contains(let content):
                    predicates
                        .append(
                            NSPredicate(format: "subject CONTAINS[c] %@ OR preview CONTAINS[c] %@",
                                        content, content, content)
                        )
                case .everywhere(let searchEverywhere):
                    if !searchEverywhere {
                        predicates.append(NSPredicate(format: "folderId = %@", filterFolderId))
                    }
                case .attachments(let searchAttachments):
                    if searchAttachments {
                        predicates.append(NSPredicate(format: "hasAttachments = true"))
                    }
                }
            }

            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            let filteredMessages = writableRealm.objects(Message.self).filter(compoundPredicate)

            // Update thread in Realm
            for message in filteredMessages {
                let newMessage = message.detached()
                newMessage.uid = "offline\(newMessage.uid)"
                newMessage.fromSearch = true

                let newThread = Thread(
                    uid: "offlineThread\(message.uid)",
                    messages: [newMessage],
                    unseenMessages: 0,
                    from: Array(message.from.detached()),
                    to: Array(message.to.detached()),
                    internalDate: newMessage.internalDate,
                    date: newMessage.date,
                    hasAttachments: newMessage.hasAttachments,
                    hasDrafts: newMessage.isDraft,
                    flagged: newMessage.flagged,
                    answered: newMessage.answered,
                    forwarded: newMessage.forwarded
                )
                newThread.makeFromSearch(using: self)
                newThread.subject = message.subject
                searchFolder.threads.insert(newThread)
            }
        }
    }

    func addToSearchHistory(value: String) async {
        try? writeTransaction { writableRealm in
            let searchHistory: SearchHistory
            if let existingSearchHistory = writableRealm.objects(SearchHistory.self).first {
                searchHistory = existingSearchHistory
            } else {
                searchHistory = SearchHistory()
                writableRealm.add(searchHistory)
            }

            if let indexToRemove = searchHistory.history.firstIndex(of: value) {
                searchHistory.history.remove(at: indexToRemove)
            }
            searchHistory.history.insert(value, at: 0)
        }
    }
}
