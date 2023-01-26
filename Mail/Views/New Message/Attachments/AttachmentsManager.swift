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

class AttachmentUploadTask: ObservableObject {
    @Published var progress: Double = 0
    var task: Task<String?, Never>?
    @Published var error: MailError?
    var uploadDone: Bool {
        return progress == 1
    }
}

class AttachmentsManager: ObservableObject {
    private let draft: Draft
    private let mailboxManager: MailboxManager
    var attachments: [Attachment] {
        return draft.attachments.filter { $0.contentId == nil }.toArray()
    }

    private(set) var attachmentUploadTasks = [String: AttachmentUploadTask]()
    var allAttachmentsUploaded: Bool {
        return attachmentUploadTasks.values.allSatisfy(\.uploadDone)
    }

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

        if oldAttachment.uuid != newAttachment.uuid {
            attachmentUploadTasks[newAttachment.uuid] = attachmentUploadTasks[oldAttachment.uuid]
            attachmentUploadTasks.removeValue(forKey: oldAttachment.uuid)
        }

        try? realm.write {
            // We need to update every field of the local attachment because embedded objects don't have a primary key
            oldAttachment.update(with: newAttachment)
        }

        objectWillChange.send()
    }

    @MainActor
    func getTotalAttachmentsSize() -> Int64 {
        return attachments.map { $0.size }.reduce(0) { $0 + $1 }
    }
    
    @MainActor
    func attachmentUploadTaskFor(uuid: String) -> AttachmentUploadTask {
        if attachmentUploadTasks[uuid] == nil {
            attachmentUploadTasks[uuid] = AttachmentUploadTask()
        }
        return attachmentUploadTasks[uuid]!
    }

    @MainActor
    func removeAttachment(_ attachment: Attachment) {
        guard let realm = attachment.realm else { return }
        let attachmentUUID = attachment.uuid
        try? realm.write {
            realm.delete(attachment)
        }
        attachmentUploadTasks[attachmentUUID]?.task?.cancel()
        attachmentUploadTasks.removeValue(forKey: attachmentUUID)

        objectWillChange.send()
    }

    @MainActor
    private func addLocalAttachment(attachment: Attachment) -> Attachment {
        attachmentUploadTasks[attachment.uuid] = AttachmentUploadTask()
        try? draft.realm?.write {
            draft.attachments.append(attachment)
        }
        objectWillChange.send()
        return attachment.freeze()
    }

    @MainActor
    private func updateAttachmentUploadProgress(attachment: Attachment, progress: Double) {
        attachmentUploadTasks[attachment.uuid]?.progress = progress
    }

    @MainActor
    private func updateAttachmentUploadError(attachment: Attachment, error: Error?) {
        if let error = error as? MailError {
            attachmentUploadTasks[attachment.uuid]?.error = error
        } else {
            attachmentUploadTasks[attachment.uuid]?.error = .unknownError
        }
    }

    @MainActor
    private func createLocalAttachment(name: String,
                                       type: UTType?,
                                       disposition: AttachmentDisposition) -> Attachment {
        let name = nameWithExtension(name: name,
                                     correspondingTo: type)
        let attachment = Attachment(uuid: UUID().uuidString,
                                    partId: "",
                                    mimeType: type?.preferredMIMEType ?? "application/octet-stream",
                                    size: 0,
                                    name: name,
                                    disposition: disposition)
        let savedAttachment = addLocalAttachment(attachment: attachment)
        return savedAttachment
    }

    private func updateLocalAttachment(url: URL, attachment: Attachment) async -> Attachment {
        let urlResources = try? url.resourceValues(forKeys: [.typeIdentifierKey, .fileSizeKey])
        let uti = UTType(urlResources?.typeIdentifier ?? "")
        let updatedName = nameWithExtension(name: attachment.name,
                                            correspondingTo: uti)
        let mimeType = uti?.preferredMIMEType ?? attachment.mimeType
        let size = Int64(urlResources?.fileSize ?? 0)

        let newAttachment = Attachment(uuid: attachment.uuid,
                                       partId: "",
                                       mimeType: mimeType,
                                       size: size,
                                       name: updatedName,
                                       disposition: attachment.disposition)

        await updateAttachment(oldAttachment: attachment, newAttachment: newAttachment)
        return newAttachment
    }

    func importAttachments(attachments: [Attachable], disposition: AttachmentDisposition = .attachment) {
        for attachment in attachments {
            Task {
                let cid = await importAttachment(attachment: attachment, disposition: disposition)
                // TODO: - Manage inline attachment
            }
        }
    }

    private func importAttachment(attachment: Attachable, disposition: AttachmentDisposition) async -> String? {
        let localAttachment = await createLocalAttachment(name: attachment.suggestedName ?? getDefaultFileName(),
                                                          type: attachment.type,
                                                          disposition: disposition)
        let importTask = Task { () -> String? in
            do {
                let url = try await attachment.writeToTemporaryURL()
                let updatedAttachment = await updateLocalAttachment(url: url, attachment: localAttachment)
                if await getTotalAttachmentsSize() > Constants.maxAttachmentsSize {
                    throw MailError.attachmentsSizeLimitReached
                }

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

        attachmentUploadTasks[localAttachment.uuid]?.task = importTask

        return await importTask.value
    }

    private func nameWithExtension(name: String, correspondingTo type: UTType?) -> String {
        guard let filenameExtension = type?.preferredFilenameExtension,
              !name.capitalized.hasSuffix(filenameExtension.capitalized) else {
            return name
        }

        return name.appending(".\(filenameExtension)")
    }

    private func getDefaultFileName() -> String {
        return filenameDateFormatter.string(from: Date())
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
