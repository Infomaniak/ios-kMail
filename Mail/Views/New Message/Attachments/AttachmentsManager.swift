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
import InfomaniakConcurrency
import InfomaniakCore
import MailCore
import PhotosUI
import SwiftUI

@MainActor final class AttachmentUploadTask: ObservableObject {
    @Published var progress: Double = 0
    var task: Task<String?, Never>?
    @Published var error: MailError?
    var uploadDone: Bool {
        return progress >= 1
    }
}

/// Abstract the fact some object was updated
protocol ContentUpdatable: AnyObject {
    /// Call to notify the content has changed.
    @MainActor func contentWillChange()

    /// Error handling
    @MainActor func handleGlobalError(_ error: MailError)
}

/// Something to track `Attachments` linked to a live `Draft`
@MainActor final class AttachmentsManager: ObservableObject {
    private let draftLocalUUID: String

    /// Async attachment operations
    private let worker: AttachmentsManagerWorker

    private let mailboxManager: MailboxManager
    private let backgroundRealm: BackgroundRealm

    /// Something to debounce content will change updates
    private let contentWillChangeSubject = PassthroughSubject<Void, Never>()
    private var contentWillChangeObserver: AnyCancellable?

    var liveDraft: Draft? {
        worker.liveDraft
    }

    var liveAttachments: [Attachment] {
        worker.liveAttachments
    }

    var allAttachmentsUploaded: Bool {
        worker.allAttachmentsUploaded
    }

    var globalError: MailError?

    init(draftLocalUUID: String, mailboxManager: MailboxManager) {
        self.draftLocalUUID = draftLocalUUID
        self.mailboxManager = mailboxManager

        // Debouncing objectWillChange helps a lot scaling with numerous attachments
        let backgroundRealm = BackgroundRealm(configuration: mailboxManager.realmConfiguration)
        self.backgroundRealm = backgroundRealm
        worker = AttachmentsManagerWorker(
            backgroundRealm: backgroundRealm,
            draftLocalUUID: draftLocalUUID,
            mailboxManager: mailboxManager
        )

        contentWillChangeObserver = contentWillChangeSubject
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { _ in
                self.objectWillChange.send()
            }

        worker.updateDelegate = self
    }

    func completeUploadedAttachments() async {
        await worker.completeUploadedAttachments()
    }

    func attachmentUploadTaskOrFinishedTask(for uuid: String) -> AttachmentUploadTask {
        worker.attachmentUploadTaskOrFinishedTask(for: uuid)
    }

    func removeAttachment(_ attachmentUUID: String) {
        Task {
            await worker.removeAttachment(attachmentUUID)
        }
    }

    private func addLocalAttachment(attachment: Attachment) async -> Attachment? {
        return await worker.addLocalAttachment(attachment: attachment)
    }

    private func createLocalAttachment(name: String,
                                       type: UTType?,
                                       disposition: AttachmentDisposition) async -> Attachment? {
        await worker.createLocalAttachment(name: name, type: type, disposition: disposition)
    }

    private func updateLocalAttachment(url: URL, attachment: Attachment) async -> Attachment {
        await worker.updateLocalAttachment(url: url, attachment: attachment)
    }

    func importAttachments(attachments: [Attachable], draft: Draft, disposition: AttachmentDisposition = .attachment) {
        Task {
            await worker.importAttachments(attachments: attachments, draft: draft, disposition: disposition)
        }
    }
}

extension AttachmentsManager: ContentUpdatable {
    func contentWillChange() {
        contentWillChangeSubject.send()
    }

    func handleGlobalError(_ error: MailError) {
        globalError = error
    }
}

final class AttachmentsManagerWorker {
    weak var updateDelegate: ContentUpdatable?

    private let mailboxManager: MailboxManager
    private let backgroundRealm: BackgroundRealm
    private let draftLocalUUID: String

    private lazy var filenameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmssSS"
        return formatter
    }()

    var attachmentUploadTasks = SendableDictionary<String, AttachmentUploadTask>()

    /// Live `Draft` getter
    var liveDraft: Draft? {
        guard let liveDraft = backgroundRealm.getRealm().object(ofType: Draft.self, forPrimaryKey: draftLocalUUID),
              !liveDraft.isInvalidated else {
            return nil
        }

        return liveDraft
    }

    var liveAttachments: [Attachment] {
        guard let liveDraft else {
            return []
        }
        return liveDraft.attachments.filter { $0.contentId == nil && !$0.isInvalidated }.toArray()
    }

    var allAttachmentsUploaded: Bool {
        return attachmentUploadTasks.values.allSatisfy(\.uploadDone)
    }

    init(backgroundRealm: BackgroundRealm, draftLocalUUID: String, mailboxManager: MailboxManager) {
        self.backgroundRealm = backgroundRealm
        self.draftLocalUUID = draftLocalUUID
        self.mailboxManager = mailboxManager
    }

    func addLocalAttachment(attachment: Attachment) async -> Attachment? {
        attachmentUploadTasks[attachment.uuid] = await AttachmentUploadTask()

        var detached: Attachment?
        await backgroundRealm.execute { realm in
            try? realm.write {
                guard let draftInContext = realm.object(ofType: Draft.self, forPrimaryKey: self.draftLocalUUID) else {
                    return
                }

                draftInContext.attachments.append(attachment)
            }

            detached = attachment.detached()
        }

        await updateDelegate?.contentWillChange()
        return detached
    }

    func updateLocalAttachment(url: URL, attachment: Attachment) async -> Attachment {
        let urlResources = try? url.resourceValues(forKeys: [.typeIdentifierKey, .fileSizeKey])
        let uti = UTType(urlResources?.typeIdentifier ?? "")
        let name = url.lastPathComponent
        let updatedName = nameWithExtension(name: name,
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

    func updateAttachment(oldAttachment: Attachment, newAttachment: Attachment) async {
        guard let oldAttachment = liveDraft?.attachments.first(where: { $0.uuid == oldAttachment.uuid }) else {
            return
        }

        let oldAttachmentUUID = oldAttachment.uuid
        let newAttachmentUUID = newAttachment.uuid

        if oldAttachmentUUID != newAttachmentUUID {
            attachmentUploadTasks[newAttachmentUUID] = attachmentUploadTasks[oldAttachmentUUID]
            attachmentUploadTasks.removeValue(forKey: oldAttachmentUUID)
        }

        await backgroundRealm.execute { realm in
            try? realm.write {
                guard let draftInContext = realm.object(ofType: Draft.self, forPrimaryKey: self.draftLocalUUID) else {
                    return
                }

                guard let liveOldAttachment = draftInContext.attachments.first(where: { $0.uuid == oldAttachmentUUID }) else {
                    return
                }

                // We need to update every field of the local attachment because embedded objects don't have a primary key
                liveOldAttachment.update(with: newAttachment)
            }
        }

        await updateDelegate?.contentWillChange()
    }

    func importAttachments(attachments: [Attachable], draft: Draft, disposition: AttachmentDisposition) async {
        guard !attachments.isEmpty else {
            return
        }

        // Cap max number of attachments, API errors out at 100
        let attachmentsSlice = attachments[safe: 0 ..< draft.availableAttachmentsSlots]

        await attachmentsSlice.concurrentForEach { attachment in
            await self.importAttachment(attachment: attachment, disposition: disposition)
            // TODO: - Manage inline attachment
        }
    }

    @discardableResult
    func importAttachment(attachment: Attachable, disposition: AttachmentDisposition) async -> String? {
        guard let localAttachment = await createLocalAttachment(name: attachment.suggestedName ?? getDefaultFileName(),
                                                                type: attachment.type,
                                                                disposition: disposition) else {
            return nil
        }

        let importTask = Task { () -> String? in
            do {
                let url = try await attachment.writeToTemporaryURL()
                let updatedAttachment = await updateLocalAttachment(url: url, attachment: localAttachment)
                let totalSize = liveAttachments.map(\.size).reduce(0) { $0 + $1 }
                guard totalSize < Constants.maxAttachmentsSize else {
                    await updateDelegate?.handleGlobalError(MailError.attachmentsSizeLimitReached)
                    await removeAttachment(updatedAttachment.uuid)
                    return nil
                }

                let remoteAttachment = try await sendAttachment(url: url, localAttachment: updatedAttachment)

                if disposition == .inline,
                   let cid = remoteAttachment?.contentId {
                    return cid
                }
            } catch {
                DDLogError("Error while creating attachment: \(error.localizedDescription)")
                await updateAttachmentUploadError(localAttachment, error: error)
            }

            return nil
        }

        if let uploadTask = attachmentUploadTasks[localAttachment.uuid] {
            await updateAttachmentUploadTask(uploadTask, task: importTask)
        }

        return await importTask.value
    }

    func createLocalAttachment(name: String,
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

    func removeAttachment(_ attachmentUUID: String) async {
        await backgroundRealm.execute { realm in
            try? realm.write {
                guard let draftInContext = realm.object(ofType: Draft.self, forPrimaryKey: self.draftLocalUUID) else {
                    return
                }

                guard let liveAttachment = draftInContext.attachments.first(where: { $0.uuid == attachmentUUID }) else {
                    return
                }

                realm.delete(liveAttachment)
            }
        }

        await attachmentUploadTasks[attachmentUUID]?.task?.cancel()
        attachmentUploadTasks.removeValue(forKey: attachmentUUID)

        await updateDelegate?.contentWillChange()
    }

    func sendAttachment(url: URL, localAttachment: Attachment) async throws -> Attachment? {
        let data = try Data(contentsOf: url)
        let remoteAttachment = try await mailboxManager.apiFetcher.createAttachment(
            mailbox: mailboxManager.mailbox,
            attachmentData: data,
            attachment: localAttachment
        ) { progress in
            guard let attachment = self.attachmentUploadTasks[localAttachment.uuid] else {
                return
            }

            Task { @MainActor in
                self.updateAttachmentUploadTaskProgress(attachment, progress: progress)
            }
        }
        await updateAttachment(oldAttachment: localAttachment, newAttachment: remoteAttachment)
        return remoteAttachment
    }

    @MainActor private func updateAttachmentUploadTask(_ uploadTask: AttachmentUploadTask, task: Task<String?, Never>?) {
        uploadTask.task = task
    }

    @MainActor private func updateAttachmentUploadTaskProgress(_ uploadTask: AttachmentUploadTask, progress: Double) {
        uploadTask.progress = progress
    }

    @MainActor private func updateAttachmentUploadError(_ attachment: Attachment, error: Error?) {
        if let error = error as? MailError {
            attachmentUploadTasks[attachment.uuid]?.error = error
        } else {
            attachmentUploadTasks[attachment.uuid]?.error = .unknownError
        }
    }
}

/// attachmentUploadTask accessors
extension AttachmentsManagerWorker {
    /// Lookup and return. New object created and returned instead
    func attachmentUploadTaskOrCreate(for uuid: String) async -> AttachmentUploadTask {
        guard let attachment = attachmentUploadTask(for: uuid) else {
            let newTask = await AttachmentUploadTask()
            attachmentUploadTasks[uuid] = newTask
            return newTask
        }

        return attachment
    }

    /// Lookup and return. New object representing a finished task instead.
    @MainActor func attachmentUploadTaskOrFinishedTask(for uuid: String) -> AttachmentUploadTask {
        guard let attachment = attachmentUploadTask(for: uuid) else {
            let finishedTask = AttachmentUploadTask()
            updateAttachmentUploadTaskProgress(finishedTask, progress: 1)
            attachmentUploadTasks[uuid] = finishedTask
            return finishedTask
        }

        return attachment
    }

    /// Lookup and return, nil if not found
    func attachmentUploadTask(for uuid: String) -> AttachmentUploadTask? {
        guard let attachment = attachmentUploadTasks[uuid] else {
            return nil
        }

        return attachment
    }

    func completeUploadedAttachments() async {
        for attachment in liveAttachments {
            let uploadTask = await attachmentUploadTaskOrCreate(for: attachment.uuid)
            await updateAttachmentUploadTaskProgress(uploadTask, progress: 1)
        }
        await updateDelegate?.contentWillChange()
    }
}

/// Naming helpers
extension AttachmentsManagerWorker {
    func nameWithExtension(name: String, correspondingTo type: UTType?) -> String {
        guard let filenameExtension = type?.preferredFilenameExtension,
              !name.capitalized.hasSuffix(filenameExtension.capitalized) else {
            return name
        }

        return name.appending(".\(filenameExtension)")
    }

    func getDefaultFileName() -> String {
        return filenameDateFormatter.string(from: Date())
    }
}
