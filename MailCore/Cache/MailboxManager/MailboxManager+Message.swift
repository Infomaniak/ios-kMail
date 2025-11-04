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
import OrderedCollections
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
            keepCacheAttributes(for: completedMessage, keepProperties: .reactions, using: writableRealm)
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
        return try await performMoveAction(messages: messages, from: origin, to: folder) { uuid, chunk, alsoMoveReactions in
            try await self.apiFetcher.move(
                mailboxUuid: uuid,
                messages: chunk,
                destinationId: folder.remoteId,
                alsoMoveReactions: alsoMoveReactions
            )
        }
    }

    func reportSpam(messages: [Message], origin: Folder?) async throws -> UndoAction {
        guard let spamFolder = getFolder(with: .spam)?.freeze() else { throw MailError.folderNotFound }

        return try await performMoveAction(
            messages: messages,
            from: origin,
            to: spamFolder
        ) { uuid, chunk, _ in
            try await self.apiFetcher.reportSpams(mailboxUuid: uuid, messages: chunk)
        }
    }

    func performMoveAction(
        messages: [Message],
        from origin: Folder?,
        to destination: Folder,
        action: @escaping (String, [Message], Bool) async throws -> UndoResponse
    ) async throws -> UndoAction {
        await markMovedLocallyIfNecessary(true, messages: messages, folder: origin)

        @InjectService var featureAvailableProvider: FeatureAvailableProvider
        let alsoMoveReactions = featureAvailableProvider.isAvailable(.emojiReaction)

        let response = await apiFetcher.batchOver(values: messages, chunkSize: Constants.apiLimit) { chunk in
            do {
                return try await action(self.mailbox.uuid, chunk, alsoMoveReactions)
            } catch {
                await self.markMovedLocallyIfNecessary(false, messages: messages, folder: origin)
            }
            return nil
        }

        Task {
            try await refreshFolder(from: messages, additionalFolder: destination)
        }
        return undoAction(for: response, messages: messages, origin: origin, destination: destination)
    }

    func delete(messages: [Message]) async throws {
        @InjectService var featureAvailableProvider: FeatureAvailableProvider
        let alsoMoveReactions = featureAvailableProvider.isAvailable(.emojiReaction)

        try await apiFetcher.delete(mailbox: mailbox, messages: messages, alsoMoveReactions: alsoMoveReactions)
        Task {
            try await refreshFolder(from: messages, additionalFolder: nil)
        }
    }

    func unsubscribe(messageResource: String) async throws {
        try await apiFetcher.unsubscribe(messageResource: messageResource)
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

    private func undoAction(
        for cancellableResponses: [UndoResponse],
        messages: [Message],
        origin: Folder?,
        destination: Folder?
    ) -> UndoAction {
        let afterUndo = {
            // We must refresh the destination folder before the source folder
            // This is important so that messages are removed and then added in the correct order
            let foldersToRefresh = OrderedSet([destination, origin].compactMap(\.self) + messages.compactMap(\.folder))

            try await self.refreshFolders(folders: foldersToRefresh)
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
