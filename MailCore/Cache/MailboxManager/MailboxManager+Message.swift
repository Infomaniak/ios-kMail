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
import InfomaniakDI
import RealmSwift

// MARK: - Message

public extension MailboxManager {
    func message(message: Message) async throws {
        // Get from API
        let completedMessage = try await apiFetcher.message(message: message)
        completedMessage.fullyDownloaded = true

        for attachment in completedMessage.attachments {
            if attachment.disposition == .attachment || attachment.contentId == nil {
                attachment.isInline = false
            } else if let contentId = attachment.contentId {
                attachment.isInline = completedMessage.body?.value?.contains(contentId) == true
            } else {
                attachment.isInline = true
            }
        }

        // Update message in Realm
        try? writeTransaction { writableRealm in
            writableRealm.add(completedMessage, update: .modified)
        }
    }

    func attachmentData(_ attachment: Attachment, progressObserver: ((Double) -> Void)?) async throws -> Data {
        guard !Task.isCancelled else {
            throw CancellationError()
        }

        @InjectService var cacheHelper: AttachmentCacheHelper
        if let cachedData = cacheHelper.getCache(resource: attachment.resource) {
            return cachedData
        } else {
            let data = try await apiFetcher.attachment(attachment: attachment, progressObserver: progressObserver)
            cacheHelper.storeCache(resource: attachment.resource, data: data)

            let safeAttachment = ThreadSafeReference(to: attachment)
            try? writeTransaction { writableRealm in
                guard let liveAttachment = writableRealm.resolve(safeAttachment) else {
                    return
                }

                liveAttachment.saved = true
            }
            return data
        }
    }

    func saveAttachmentLocally(attachment: Attachment, progressObserver: ((Double) -> Void)?) async {
        do {
            let data = try await attachmentData(attachment, progressObserver: progressObserver)
            let url = attachment.getLocalURL(userId: mailbox.userId, mailboxId: mailbox.mailboxId)
            let parentFolder = url.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: parentFolder.path) {
                try FileManager.default.createDirectory(at: parentFolder, withIntermediateDirectories: true)
            }
            try data.write(to: url)
        } catch {
            // Handle error
            print("Failed to save attachment: \(error)")
        }
    }

    func markAsSeen(message: Message, seen: Bool = true) async throws {
        if seen {
            var messages = [message]
            messages.append(contentsOf: message.duplicates)
            try await markAsSeen(messages: messages, seen: seen)
        } else {
            try await markAsSeen(messages: [message], seen: seen)
        }
    }

    func move(messages: [Message], to folderRole: FolderRole, origin: Folder? = nil) async throws -> UndoAction {
        guard let folder = getFolder(with: folderRole)?.freeze() else { throw MailError.folderNotFound }
        return try await move(messages: messages, to: folder, origin: origin)
    }

    func move(messages: [Message], to folder: Folder, origin: Folder? = nil) async throws -> UndoAction {
        return try await performMoveAction(
            messages: messages,
            origin: origin
        ) { uuid, chunk in
            try await self.apiFetcher.move(mailboxUuid: uuid, messages: chunk, destinationId: folder.remoteId)
        }
    }

    func reportSpam(messages: [Message], origin: Folder?) async throws -> UndoAction {
        return try await performMoveAction(
            messages: messages,
            origin: origin
        ) { uuid, chunk in
            try await self.apiFetcher.reportSpams(mailboxUuid: uuid, messages: chunk)
        }
    }

    func performMoveAction(
        messages: [Message],
        origin: Folder?,
        action: @escaping (String, [Message]) async throws -> UndoResponse
    ) async throws -> UndoAction {
        let originalThreads = messages.flatMap { $0.threads.filter { $0.folder == origin } }
        await markMovedLocally(true, threads: originalThreads)

        let response = await apiFetcher.batchOver(values: messages, chunkSize: Constants.apiLimit) { chunk in
            do {
                return try await action(self.mailbox.uuid, chunk)
            } catch {
                await self.markMovedLocally(false, threads: originalThreads)
            }
            return nil
        }

        Task {
            try await refreshFolder(from: messages, additionalFolder: origin)
        }
        return undoAction(for: response, and: messages)
    }

    func delete(messages: [Message]) async throws {
        try await apiFetcher.delete(mailbox: mailbox, messages: messages)
        Task {
            try await refreshFolder(from: messages, additionalFolder: nil)
        }
    }

    // MARK: Private

    func markAsSeen(messages: [Message], seen: Bool) async throws {
        await updateLocally(.seen, value: seen, messages: messages)

        if seen {
            _ = await apiFetcher.batchOver(values: messages, chunkSize: Constants.apiLimit) { chunk in
                do {
                    try await self.apiFetcher.markAsSeen(mailbox: self.mailbox, messages: chunk)
                } catch {
                    await self.updateLocally(.seen, value: !seen, messages: chunk)
                }
            }
        } else {
            _ = await apiFetcher.batchOver(values: messages, chunkSize: Constants.apiLimit) { chunk in
                do {
                    try await self.apiFetcher.markAsUnseen(mailbox: self.mailbox, messages: chunk)
                } catch {
                    await self.updateLocally(.seen, value: !seen, messages: chunk)
                }
            }
        }

        try await refreshFolder(from: messages, additionalFolder: nil)

        // TODO: Remove after fix
        SentryDebug.listIncoherentMessageUpdate(messages: messages, actualSeen: seen)
    }

    /// Set starred the given messages.
    /// - Important: This methods stars only the messages you passes, no processing is done to add duplicates or remove drafts
    func star(messages: [Message], starred: Bool) async throws {
        await updateLocally(.star, value: starred, messages: messages)

        if starred {
            _ = await apiFetcher.batchOver(values: messages, chunkSize: Constants.apiLimit) { chunk in
                do {
                    try await self.apiFetcher.star(mailbox: self.mailbox, messages: chunk)
                } catch {
                    await self.updateLocally(.star, value: !starred, messages: chunk)
                }
            }
        } else {
            _ = await apiFetcher.batchOver(values: messages, chunkSize: Constants.apiLimit) { chunk in
                do {
                    try await self.apiFetcher.unstar(mailbox: self.mailbox, messages: chunk)
                } catch {
                    await self.updateLocally(.star, value: !starred, messages: chunk)
                }
            }
        }

        try await refreshFolder(from: messages, additionalFolder: nil)
    }

    private func undoAction(for cancellableResponses: [UndoResponse], and messages: [Message]) -> UndoAction {
        let afterUndo = {
            try await self.refreshFolder(from: messages, additionalFolder: nil)
            return true
        }
        let undo = {
            let results = try await cancellableResponses.asyncMap { cancellableResponse in
                try await self.apiFetcher.undoAction(resource: cancellableResponse.undoResource)
            }
            return !results.contains { $0 == false }
        }
        return UndoAction(undo: undo, afterUndo: afterUndo)
    }
}
