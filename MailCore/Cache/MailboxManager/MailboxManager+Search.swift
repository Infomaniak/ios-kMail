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

        let realm = getRealm()
        try? realm.uncheckedSafeWrite {
            realm.add(searchFolder, update: .modified)
        }
        return searchFolder
    }

    func clearSearchResults(searchFolder: Folder, using realm: Realm) {
        try? realm.safeWrite {
            realm.delete(realm.objects(Message.self).where { $0.fromSearch == true })
            realm.delete(realm.objects(Thread.self).where { $0.fromSearch == true })
            searchFolder.threads.removeAll()
        }
    }

    func clearSearchResults() async {
        await backgroundRealm.execute { realm in
            guard let searchFolder = realm.objects(Folder.self).where({ $0.remoteId == Constants.searchFolderId }).first else {
                return
            }

            self.clearSearchResults(searchFolder: searchFolder, using: realm)
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
        await backgroundRealm.execute { realm in
            for thread in threadResult.threads ?? [] {
                thread.makeFromSearch(using: realm)

                for message in thread.messages where realm.object(ofType: Message.self, forPrimaryKey: message.uid) == nil {
                    message.fromSearch = true
                }
            }
        }

        if let searchFolder {
            await saveSearchThreads(result: threadResult, searchFolder: searchFolder)
        }
    }

    func searchThreadsOffline(searchFolder: Folder?, filterFolderId: String,
                              searchFilters: [SearchCondition]) async {
        await backgroundRealm.execute { realm in
            guard let searchFolder = searchFolder?.fresh(using: realm) else {
                self.logError(.missingFolder)
                return
            }

            self.clearSearchResults(searchFolder: searchFolder, using: realm)

            var predicates: [NSPredicate] = []
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

            let filteredMessages = realm.objects(Message.self).filter(compoundPredicate)

            // Update thread in Realm
            try? realm.safeWrite {
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
                        date: newMessage.date,
                        hasAttachments: newMessage.hasAttachments,
                        hasDrafts: newMessage.isDraft,
                        flagged: newMessage.flagged,
                        answered: newMessage.answered,
                        forwarded: newMessage.forwarded
                    )
                    newThread.makeFromSearch(using: realm)
                    newThread.subject = message.subject
                    searchFolder.threads.insert(newThread)
                }
            }
        }
    }

    func addToSearchHistory(value: String) async {
        return await backgroundRealm.execute { realm in
            try? realm.safeWrite {
                let searchHistory: SearchHistory
                if let existingSearchHistory = realm.objects(SearchHistory.self).first {
                    searchHistory = existingSearchHistory
                } else {
                    searchHistory = SearchHistory()
                    realm.add(searchHistory)
                }

                if let indexToRemove = searchHistory.history.firstIndex(of: value) {
                    searchHistory.history.remove(at: indexToRemove)
                }
                searchHistory.history.insert(value, at: 0)
            }
        }
    }
}
