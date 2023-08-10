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

// MARK: - Thread

public extension MailboxManager {
    func threads(folder: Folder, fetchCurrentFolderCompleted: (() -> Void) = {}) async throws {
        try await messages(folder: folder.freezeIfNeeded())
        fetchCurrentFolderCompleted()

        var roles: [FolderRole] {
            switch folder.role {
            case .inbox:
                return [.sent, .draft]
            case .sent:
                return [.inbox, .draft]
            case .draft:
                return [.inbox, .sent]
            default:
                return []
            }
        }

        for folderRole in roles {
            guard !Task.isCancelled else { break }
            if let realFolder = getFolder(with: folderRole) {
                try await messages(folder: realFolder.freezeIfNeeded())
            }
        }
    }

    internal func deleteMessages(uids: [String]) async {
        guard !uids.isEmpty && !Task.isCancelled else { return }

        await backgroundRealm.execute { realm in
            let batchSize = 100
            for index in stride(from: 0, to: uids.count, by: batchSize) {
                autoreleasepool {
                    let uidsBatch = Array(uids[index ..< min(index + batchSize, uids.count)])

                    let messagesToDelete = realm.objects(Message.self).where { $0.uid.in(uidsBatch) }
                    var threadsToUpdate = Set<Thread>()
                    var threadsToDelete = Set<Thread>()
                    var draftsToDelete = Set<Draft>()

                    for message in messagesToDelete {
                        if let draft = self.draft(messageUid: message.uid, using: realm) {
                            draftsToDelete.insert(draft)
                        }
                        for parent in message.threads {
                            threadsToUpdate.insert(parent)
                        }
                    }

                    let foldersToUpdate = Set(threadsToUpdate.compactMap(\.folder))

                    try? realm.safeWrite {
                        realm.delete(draftsToDelete)
                        realm.delete(messagesToDelete)
                        for thread in threadsToUpdate {
                            if thread.messageInFolderCount == 0 {
                                threadsToDelete.insert(thread)
                            } else {
                                do {
                                    try thread.recomputeOrFail()
                                } catch {
                                    threadsToDelete.insert(thread)
                                    SentryDebug.threadHasNilLastMessageFromFolderDate(thread: thread)
                                }
                            }
                        }
                        realm.delete(threadsToDelete)
                        for updateFolder in foldersToUpdate {
                            updateFolder.computeUnreadCount()
                        }
                    }
                }
            }
        }
    }

    internal func saveThreads(result: ThreadResult, parent: Folder) async {
        await backgroundRealm.execute { realm in
            guard let parentFolder = parent.fresh(using: realm) else { return }

            let fetchedThreads = MutableSet<Thread>()
            fetchedThreads.insert(objectsIn: result.threads ?? [])

            for thread in fetchedThreads {
                for message in thread.messages {
                    self.keepCacheAttributes(for: message, keepProperties: .standard, using: realm)
                }
            }

            // Update thread in Realm
            try? realm.safeWrite {
                // Clean old threads after fetching first page
                if result.currentOffset == 0 {
                    parentFolder.lastUpdate = Date()
                    realm.delete(parentFolder.threads.flatMap(\.messages).filter { $0.fromSearch == true })
                    realm.delete(parentFolder.threads.filter { $0.fromSearch == true })
                }
                realm.add(fetchedThreads, update: .modified)
                parentFolder.threads.insert(objectsIn: fetchedThreads)
                parentFolder.unreadCount = result.folderUnseenMessages
            }
        }
    }

    func toggleRead(threads: [Thread]) async throws {
        if threads.contains(where: \.hasUnseenMessages) {
            var messages = threads.flatMap(\.messages)
            messages.append(contentsOf: messages.flatMap(\.duplicates))
            try await markAsSeen(messages: messages, seen: true)
        } else {
            let messages = threads.flatMap { thread in
                thread.lastMessageAndItsDuplicateToExecuteAction(currentMailboxEmail: mailbox.email)
            }
            try await markAsSeen(messages: messages, seen: false)
        }
    }

    func move(threads: [Thread], to folderRole: FolderRole) async throws -> UndoRedoAction {
        guard let folder = getFolder(with: folderRole)?.freeze() else { throw MailError.folderNotFound }
        return try await move(threads: threads, to: folder)
    }

    func move(threads: [Thread], to folder: Folder) async throws -> UndoRedoAction {
        var messages = threads.flatMap(\.messages).filter { $0.folder == threads.first?.folder }
        messages.append(contentsOf: messages.flatMap(\.duplicates))

        return try await move(messages: messages, to: folder)
    }

    func moveOrDelete(threads: [Thread]) async throws {
        let messagesToMoveOrDelete = threads.flatMap(\.messages)
        try await moveOrDelete(messages: messagesToMoveOrDelete)
    }

    func toggleStar(threads: [Thread]) async throws {
        let messagesToToggleStar = threads.flatMap { thread in
            thread.lastMessageAndItsDuplicateToExecuteAction(currentMailboxEmail: mailbox.email)
        }
        try await toggleStar(messages: messagesToToggleStar)
    }
}
