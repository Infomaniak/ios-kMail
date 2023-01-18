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

import CocoaLumberjackSwift
import Foundation
import MailCore
import PhotosUI
import SwiftUI

struct AttachmentUploadTask {
    var progress: Double
    var error: MailError?
}

class AttachmentsManager: ObservableObject {
    private let draft: Draft
    private let mailboxManager: MailboxManager
    var attachments: [Attachment] {
        return draft.attachments.filter { $0.contentId == nil }.toArray()
    }

    private(set) var attachmentUploadTasks = [String: AttachmentUploadTask]()

    private lazy var filenameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmssSS"
        return formatter
    }()

    init(draft: Draft, mailboxManager: MailboxManager) {
        self.draft = draft
        self.mailboxManager = mailboxManager
    }

    @MainActor
    private func updateAttachment(oldAttachment: Attachment, newAttachment: Attachment) {
        guard let realm = draft.realm,
              let oldAttachment = draft.attachments.first(where: { $0.uuid == oldAttachment.uuid }) else {
            return
        }

        try? realm.write {
            // We need to update every field of the local attachment because embedded objects don't have a primary key
            oldAttachment.update(with: newAttachment)
        }

        objectWillChange.send()
    }

    @MainActor
    func removeAttachment(_ attachment: Attachment) {
        guard let realm = attachment.realm else { return }
        try? realm.write {
            realm.delete(attachment)
        }
        objectWillChange.send()
    }

    @MainActor
    private func addLocalAttachment(attachment: Attachment) -> Attachment {
        attachmentUploadTasks[attachment.uuid ?? ""] = AttachmentUploadTask(progress: 0, error: nil)
        try? draft.realm?.write {
            draft.attachments.append(attachment)
        }
        objectWillChange.send()
        return attachment.freeze()
    }

    @MainActor
    private func updateAttachmentUploadProgress(attachment: Attachment, progress: Double) {
        guard let uuid = attachment.uuid else { return }
        attachmentUploadTasks[uuid]?.progress = progress
        objectWillChange.send()
    }

    @MainActor
    private func updateAttachmentUploadError(attachment: Attachment, error: Error?) {
        guard let uuid = attachment.uuid else { return }

        if let error = error as? MailError {
            attachmentUploadTasks[uuid]?.error = error
        } else {
            attachmentUploadTasks[uuid]?.error = .unknownError
        }
        objectWillChange.send()
    }

    private func createLocalAttachment(name: String,
                                       type: UTType?,
                                       disposition: AttachmentDisposition) async -> Attachment {
        let name = nameWithExtension(name: name,
                                     correspondingTo: type)
        let attachment = Attachment(uuid: UUID().uuidString,
                                    partId: "",
                                    mimeType: type?.preferredMIMEType ?? "application/octet-stream",
                                    size: 0,
                                    name: name,
                                    disposition: disposition)
        let savedAttachment = await addLocalAttachment(attachment: attachment)
        return savedAttachment
    }

    private func updateLocalAttachment(url: URL, attachment: Attachment) async -> Attachment {
        let urlResources = try? url.resourceValues(forKeys: [.typeIdentifierKey, .fileSizeKey])
        let uti = UTType(urlResources?.typeIdentifier ?? "")
        let mimeType = uti?.preferredMIMEType ?? attachment.mimeType
        let size = Int64(urlResources?.fileSize ?? 0)

        let newAttachment = Attachment(uuid: attachment.uuid,
                                       partId: "",
                                       mimeType: mimeType,
                                       size: size,
                                       name: attachment.name,
                                       disposition: attachment.disposition)

        await updateAttachment(oldAttachment: attachment, newAttachment: newAttachment)
        return newAttachment
    }

    func addDocumentAttachment(urls: [URL]) {
        Task {
            await withTaskGroup(of: Void.self) { group in
                for url in urls {
                    group.addTask {
                        let localAttachment = await self.createLocalAttachment(name: url.lastPathComponent,
                                                                               type: UTType.data,
                                                                               disposition: .attachment)
                        let updatedAttachment = await self.updateLocalAttachment(url: url, attachment: localAttachment)
                        do {
                            _ = try await self.sendAttachment(url: url, localAttachment: updatedAttachment)
                        } catch {
                            DDLogError("Error while creating attachment: \(error.localizedDescription)")
                            await self.updateAttachmentUploadError(attachment: localAttachment, error: error)
                        }
                    }
                }
            }
        }
    }

    func addImageAttachments(results: [PHPickerResult], disposition: AttachmentDisposition = .attachment) {
        Task {
            let itemProviders = results.map(\.itemProvider)
            await withTaskGroup(of: Void.self) { group in
                for itemProvider in itemProviders {
                    group.addTask {
                        let cid = await self.addImageAttachment(itemProvider: itemProvider, disposition: disposition)
                        // TODO: - Manage inline attachment
                    }
                }
            }
        }
    }

    private func addImageAttachment(itemProvider: NSItemProvider, disposition: AttachmentDisposition) async -> String? {
        let typeIdentifier = itemProvider.registeredTypeIdentifiers
            .first { UTType($0)?.conforms(to: .image) == true || UTType($0)?.conforms(to: .movie) == true } ?? ""
        let name = itemProvider.suggestedName ?? getDefaultFileName()
        let localAttachment = await createLocalAttachment(name: name,
                                                          type: UTType(typeIdentifier),
                                                          disposition: disposition)
        do {
            let url = try await loadFileRepresentation(itemProvider, typeIdentifier: typeIdentifier)
            let updatedAttachment = await updateLocalAttachment(url: url, attachment: localAttachment)
            let remoteAttachment = try await sendAttachment(url: url, localAttachment: updatedAttachment)

            if disposition == .inline,
               let cid = remoteAttachment?.contentId {
                return cid
            }
        } catch {
            DDLogError("Error while creating attachment: \(error.localizedDescription)")
            await updateAttachmentUploadError(attachment: localAttachment, error: error)
        }

        return nil
    }

    func addCameraAttachment(data: Data, disposition: AttachmentDisposition = .attachment) {
        Task {
            let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            let temporaryFileURL = temporaryURL.appendingPathComponent(getDefaultFileName()).appendingPathExtension("jpeg")
            let localAttachment = await self.createLocalAttachment(name: temporaryFileURL.lastPathComponent,
                                                                   type: UTType.image,
                                                                   disposition: .attachment)
            do {
                try FileManager.default.createDirectory(at: temporaryURL, withIntermediateDirectories: true)
                try data.write(to: temporaryFileURL)

                let updatedAttachment = await self.updateLocalAttachment(url: temporaryURL, attachment: localAttachment)
                let remoteAttachment = try await self.sendAttachment(url: temporaryFileURL, localAttachment: updatedAttachment)

                if disposition == .inline,
                   let cid = remoteAttachment?.contentId {
                    // TODO: - Manage inline attachment
                }
            } catch {
                DDLogError("Error while creating attachment: \(error.localizedDescription)")
                await updateAttachmentUploadError(attachment: localAttachment, error: error)
            }
        }
    }

    func loadFileRepresentation(_ itemProvider: NSItemProvider, typeIdentifier: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { fileProviderURL, error in
                guard let fileProviderURL else {
                    continuation.resume(throwing: error ?? MailError.unknownError)
                    return
                }

                do {
                    let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                    let temporaryFileURL = temporaryURL.appendingPathComponent(fileProviderURL.lastPathComponent)
                    try FileManager.default.createDirectory(at: temporaryURL, withIntermediateDirectories: true)
                    try FileManager.default.copyItem(atPath: fileProviderURL.path, toPath: temporaryFileURL.path)
                    continuation.resume(returning: temporaryFileURL)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func getDefaultFileName() -> String {
        return filenameDateFormatter.string(from: Date())
    }

    private func nameWithExtension(name: String, correspondingTo type: UTType?) -> String {
        guard let filenameExtension = type?.preferredFilenameExtension,
              !name.capitalized.hasSuffix(filenameExtension.capitalized) else {
            return name
        }

        return name.appending(".\(filenameExtension)")
    }

    private func sendAttachment(
        url: URL,
        localAttachment: Attachment
    ) async throws -> Attachment? {
        let data = try Data(contentsOf: url)
        let remoteAttachment = try await mailboxManager.apiFetcher.createAttachment(
            mailbox: mailboxManager.mailbox,
            attachmentData: data,
            attachment: localAttachment
        ) { progress in
            Task { [weak self] in
                await self?.updateAttachmentUploadProgress(attachment: localAttachment, progress: progress)
            }
        }
        await updateAttachment(oldAttachment: localAttachment, newAttachment: remoteAttachment)
        return remoteAttachment
    }
}
