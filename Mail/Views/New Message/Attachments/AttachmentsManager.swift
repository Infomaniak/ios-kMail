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
import Combine
import Foundation
import InfomaniakCore
import MailCore
import PhotosUI
import SwiftUI

final class AttachmentUploadTask: ObservableObject {
    @Published var progress: Double = 0
    var task: Task<String?, Never>?
    @Published var error: MailError?
    var uploadDone: Bool {
        return progress >= 1
    }
}

@MainActor
final class AttachmentsManager: ObservableObject {
    private let draft: Draft
    private let mailboxManager: MailboxManager
    private let parallelTaskMapper = ParallelTaskMapper()
    private let backgroundRealm: BackgroundRealm

    /// Something to debounce content will change updates
    private let contentWillChangeSubject = PassthroughSubject<Void, Never>()
    private var contentWillChangeObserver: AnyCancellable?

    var attachments: [Attachment] {
        return draft.attachments.filter { $0.contentId == nil }.toArray()
    }

    private var attachmentUploadTasks = SendableDictionary<String, AttachmentUploadTask>()

    var allAttachmentsUploaded: Bool {
        return attachmentUploadTasks.values.allSatisfy(\.uploadDone)
    }

    var globalError: MailError?

    private lazy var filenameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmssSS"
        return formatter
    }()

    init(draft: Draft, mailboxManager: MailboxManager) {
        self.draft = draft
        self.mailboxManager = mailboxManager

        // Debouncing objectWillChange helps a lot scaling with numerous attachments
        backgroundRealm = BackgroundRealm(configuration: mailboxManager.realmConfiguration)
        contentWillChangeObserver = contentWillChangeSubject
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { _ in
                self.objectWillChange.send()
            }
    }

    func completeUploadedAttachments() {
        for attachment in attachments {
            let uploadTask = attachmentUploadTaskOrCreate(for: attachment.uuid)
            uploadTask.progress = 1
        }
        contentWillChangeSubject.send()
    }

    private func updateAttachment(oldAttachment: Attachment, newAttachment: Attachment) async {
        guard let oldAttachment = draft.attachments.first(where: { $0.uuid == oldAttachment.uuid }) else {
            return
        }

        let oldAttachmentUUID = oldAttachment.uuid
        let newAttachmentUUID = newAttachment.uuid
        let primaryKey = draft.localUUID

        if oldAttachmentUUID != newAttachmentUUID {
            attachmentUploadTasks[newAttachmentUUID] = attachmentUploadTasks[oldAttachmentUUID]
            attachmentUploadTasks.removeValue(forKey: oldAttachmentUUID)
        }

        await backgroundRealm.execute { realm in
            try? realm.write {
                guard let draftInContext = realm.object(ofType: Draft.self, forPrimaryKey: primaryKey) else {
                    return
                }

                guard let liveOldAttachment = draftInContext.attachments.first(where: { $0.uuid == oldAttachmentUUID }) else {
                    return
                }

                // We need to update every field of the local attachment because embedded objects don't have a primary key
                liveOldAttachment.update(with: newAttachment)
            }
        }

        contentWillChangeSubject.send()
    }

    /// Lookup and return. New object created and returned instead
    func attachmentUploadTaskOrCreate(for uuid: String) -> AttachmentUploadTask {
        guard let attachment = attachmentUploadTask(for: uuid) else {
            let newTask = AttachmentUploadTask()
            attachmentUploadTasks[uuid] = newTask
            return newTask
        }

        return attachment
    }

    /// Lookup and return. New object representing a finished task instead.
    func attachmentUploadTaskOrFinishedTask(for uuid: String) -> AttachmentUploadTask {
        guard let attachment = attachmentUploadTask(for: uuid) else {
            let finishedTask = AttachmentUploadTask()
            finishedTask.progress = 1
            attachmentUploadTasks[uuid] = finishedTask
            return finishedTask
        }

        return attachment
    }

    /// Lookup and return, nil if not found
    private func attachmentUploadTask(for uuid: String) -> AttachmentUploadTask? {
        guard let attachment = attachmentUploadTasks[uuid] else {
            return nil
        }

        return attachment
    }

    func removeAttachment(_ attachment: Attachment) {
        let attachmentUUID = attachment.uuid
        let primaryKey = draft.localUUID

        Task {
            await backgroundRealm.execute { realm in
                try? realm.write {
                    guard let draftInContext = realm.object(ofType: Draft.self, forPrimaryKey: primaryKey) else {
                        return
                    }

                    guard let liveAttachment = draftInContext.attachments.first(where: { $0.uuid == attachmentUUID }) else {
                        return
                    }

                    realm.delete(liveAttachment)
                }
            }

            attachmentUploadTasks[attachmentUUID]?.task?.cancel()
            attachmentUploadTasks.removeValue(forKey: attachmentUUID)

            contentWillChangeSubject.send()
        }
    }

    private func addLocalAttachment(attachment: Attachment) async -> Attachment? {
        attachmentUploadTasks[attachment.uuid] = AttachmentUploadTask()
        let primaryKey = draft.localUUID

        var detached: Attachment?
        await backgroundRealm.execute { realm in
            try? realm.write {
                guard let draftInContext = realm.object(ofType: Draft.self, forPrimaryKey: primaryKey) else {
                    return
                }

                draftInContext.attachments.append(attachment)
            }

            detached = attachment.detached()
        }

        contentWillChangeSubject.send()
        return detached
    }

    private func updateAttachmentUploadError(attachment: Attachment, error: Error?) {
        if let error = error as? MailError {
            attachmentUploadTasks[attachment.uuid]?.error = error
        } else {
            attachmentUploadTasks[attachment.uuid]?.error = .unknownError
        }
    }

    private func createLocalAttachment(name: String,
                                       type: UTType?,
                                       disposition: AttachmentDisposition) async -> Attachment? {
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

    func importAttachments(attachments: [Attachable], draft: Draft, disposition: AttachmentDisposition = .attachment) {
        guard !attachments.isEmpty else {
            return
        }

        // Cap max number of attachments, API errors out at 100
        let attachmentsSlice = attachments[safe: 0 ..< draft.availableAttachmentsSlots]

        Task.detached {
            try? await self.parallelTaskMapper.map(collection: attachmentsSlice) { attachment in
                _ = await self.importAttachment(attachment: attachment, disposition: disposition)
                // TODO: - Manage inline attachment
            }
        }
    }

    private func importAttachment(attachment: Attachable, disposition: AttachmentDisposition) async -> String? {
        guard let localAttachment = await createLocalAttachment(name: attachment.suggestedName ?? getDefaultFileName(),
                                                                type: attachment.type,
                                                                disposition: disposition) else {
            return nil
        }

        let importTask = Task { () -> String? in
            do {
                let url = try await attachment.writeToTemporaryURL()
                let updatedAttachment = await updateLocalAttachment(url: url, attachment: localAttachment)
                let totalSize = attachments.map { $0.size }.reduce(0) { $0 + $1 }
                guard totalSize < Constants.maxAttachmentsSize else {
                    globalError = MailError.attachmentsSizeLimitReached
                    removeAttachment(updatedAttachment)
                    return nil
                }

                let remoteAttachment = try await sendAttachment(url: url, localAttachment: updatedAttachment)

                if disposition == .inline,
                   let cid = remoteAttachment?.contentId {
                    return cid
                }
            } catch {
                DDLogError("Error while creating attachment: \(error.localizedDescription)")
                updateAttachmentUploadError(attachment: localAttachment, error: error)
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
                self?.attachmentUploadTasks[localAttachment.uuid]?.progress = progress
            }
        }
        await updateAttachment(oldAttachment: localAttachment, newAttachment: remoteAttachment)
        return remoteAttachment
    }
}
