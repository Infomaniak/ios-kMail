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
import InfomaniakConcurrency
import InfomaniakCore
import InfomaniakCoreDB
import OSLog
import UniformTypeIdentifiers

/// Abstracts that some attachment was updated
public protocol AttachmentsContentUpdatable: AnyObject {
    /// Call to notify the content has changed.
    @MainActor func contentWillChange()

    /// Error handling
    @MainActor func handleGlobalError(_ error: LocalError)
}

/// Public interface of the worker
public protocol AttachmentsManagerWorkable {
    /// Live `Draft` getter
    var liveDraft: Draft? { get }

    /// True if all uploaded
    var allAttachmentsUploaded: Bool { get }

    /// Set the updateDelegate
    func setUpdateDelegate(_ updateDelegate: AttachmentsContentUpdatable)

    /// Marks all uploads as done
    func completeUploadedAttachments() async

    /// Removes an attachment for a specific primary key
    /// - Parameter attachmentUUID: primary key of the object
    func removeAttachment(_ attachmentUUID: String) async

    /// Uploads remotely a collection of `Attachable`
    /// - Parameters:
    ///   - attachments: collection of `Attachable`
    ///   - draft: Draft containing the attachments
    ///   - disposition: Is it inline ?
    func importAttachments(attachments: [Attachable], draft: Draft, disposition: AttachmentDisposition) async

    /// Lookup and return _or_ new object representing a finished task instead.
    @MainActor func attachmentUploadTaskOrFinishedTask(for uuid: String) -> AttachmentTask
}

/// Transactionable
extension AttachmentsManagerWorker: TransactionablePassthrough {}

// MARK: - AttachmentsManagerWorker

public final class AttachmentsManagerWorker {
    weak var updateDelegate: AttachmentsContentUpdatable?

    private let mailboxManager: MailboxManager
    private let draftLocalUUID: String

    public let transactionExecutor: Transactionable

    private lazy var filenameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmssSS"
        return formatter
    }()

    var attachmentUploadTasks = SendableDictionary<String, AttachmentTask>()

    var detachedAttachments: [Attachment] {
        liveAttachments.map { $0.detached() }
    }

    var attachmentsTitles: [String?]? {
        didSet {
            // Only pre-fill subject when sharing from the outside
            guard Bundle.main.isExtension else {
                return
            }

            guard let draft = transactionExecutor.fetchObject(ofType: Draft.self, forPrimaryKey: draftLocalUUID),
                  !draft.isInvalidated,
                  draft.subject.isEmpty else {
                return
            }

            guard let attachmentTitle = attachmentsTitles?.compactMap({ $0 }).first else {
                return
            }

            try? transactionExecutor.writeTransaction { writableRealm in
                guard let liveDraft = writableRealm.object(ofType: Draft.self, forPrimaryKey: draftLocalUUID) else {
                    return
                }
                liveDraft.subject = attachmentTitle
            }
        }
    }

    public init(draftLocalUUID: String, mailboxManager: MailboxManager) {
        self.draftLocalUUID = draftLocalUUID
        self.mailboxManager = mailboxManager
        let realmAccessor = MailCoreRealmAccessor(realmConfiguration: mailboxManager.realmConfiguration)
        transactionExecutor = TransactionExecutor(realmAccessible: realmAccessor)
    }

    func addLocalAttachment(attachment: Attachment) async -> Attachment? {
        attachmentUploadTasks[attachment.uuid] = await AttachmentTask()

        var detached: Attachment?
        try? writeTransaction { writableRealm in
            guard let draftInContext = writableRealm.object(ofType: Draft.self, forPrimaryKey: self.draftLocalUUID) else {
                return
            }

            draftInContext.attachments.append(attachment)
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

        try? writeTransaction { writableRealm in
            guard let draftInContext = writableRealm.object(ofType: Draft.self, forPrimaryKey: self.draftLocalUUID) else {
                return
            }

            guard let liveOldAttachment = draftInContext.attachments.first(where: { $0.uuid == oldAttachmentUUID }) else {
                return
            }

            // We need to update every field of the local attachment because embedded objects don't have a primary key
            liveOldAttachment.update(with: newAttachment)
        }

        await updateDelegate?.contentWillChange()
    }

    func importAttachment(attachment: Attachable, disposition: AttachmentDisposition) async -> String? {
        guard let localAttachment = await createLocalAttachment(name: attachment.suggestedName ?? getDefaultFileName(),
                                                                type: attachment.type,
                                                                disposition: disposition) else {
            return nil
        }

        let importTask = Task { () -> String? in
            do {
                let attachmentResult = try await attachment.writeToTemporaryURL()
                let attachmentURL = attachmentResult.url
                let attachmentTitle = attachmentResult.title

                let updatedAttachment = await updateLocalAttachment(url: attachmentURL, attachment: localAttachment)
                let totalSize = liveAttachments.map(\.size).reduce(0) { $0 + $1 }
                guard totalSize < Constants.maxAttachmentsSize else {
                    await updateDelegate?.handleGlobalError(MailError.attachmentsSizeLimitReached)
                    await removeAttachment(updatedAttachment.uuid)
                    return nil
                }

                try await sendAttachment(url: attachmentURL, localAttachment: updatedAttachment)
                return attachmentTitle

            } catch {
                Logger.general.error("Error while creating attachment: \(error.localizedDescription)")
                await updateAttachmentUploadError(localAttachment, error: error)
                return nil
            }
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

    @discardableResult
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
        remoteAttachment.temporaryLocalUrl = url.path
        await updateAttachment(oldAttachment: localAttachment, newAttachment: remoteAttachment)
        return remoteAttachment
    }

    func attachmentUploadTaskOrCreate(for uuid: String) async -> AttachmentTask {
        guard let attachment = attachmentUploadTask(for: uuid) else {
            let newTask = await AttachmentTask()
            attachmentUploadTasks[uuid] = newTask
            return newTask
        }

        return attachment
    }

    func attachmentUploadTask(for uuid: String) -> AttachmentTask? {
        guard let attachment = attachmentUploadTasks[uuid] else {
            return nil
        }

        return attachment
    }

    @MainActor private func updateAttachmentUploadTask(_ uploadTask: AttachmentTask, task: Task<String?, Never>?) {
        uploadTask.task = task
    }

    @MainActor private func updateAttachmentUploadTaskProgress(_ uploadTask: AttachmentTask, progress: Double) {
        uploadTask.progress = progress
    }

    @MainActor private func updateAttachmentUploadError(_ attachment: Attachment, error: Error?) {
        if let error = error as? LocalError {
            attachmentUploadTasks[attachment.uuid]?.error = error
        } else {
            attachmentUploadTasks[attachment.uuid]?.error = MailError.unknownError
        }
    }
}

// MARK: - AttachmentsManagerWorkable

extension AttachmentsManagerWorker: AttachmentsManagerWorkable {
    public var liveDraft: Draft? {
        guard let liveDraft = transactionExecutor.fetchObject(ofType: Draft.self, forPrimaryKey: draftLocalUUID),
              !liveDraft.isInvalidated else {
            return nil
        }

        return liveDraft
    }

    public var liveAttachments: [Attachment] {
        guard let liveDraft else {
            return []
        }
        return liveDraft.attachments.filter { attachment in
            guard !attachment.isInvalidated else { return false }
            guard let contentId = attachment.contentId else { return true }
            return contentId.isEmpty
        }.toArray()
    }

    public var allAttachmentsUploaded: Bool {
        return attachmentUploadTasks.values.allSatisfy(\.isAttachmentComplete)
    }

    public func setUpdateDelegate(_ updateDelegate: AttachmentsContentUpdatable) {
        self.updateDelegate = updateDelegate
    }

    public func importAttachments(attachments: [Attachable],
                                  draft: Draft,
                                  disposition: AttachmentDisposition) async {
        guard !attachments.isEmpty else {
            return
        }

        // Cap max number of attachments, API errors out at 100
        let attachmentsSlice = attachments[safe: 0 ..< draft.availableAttachmentsSlots]

        let titles: [String?] = await attachmentsSlice.concurrentMap { attachment in
            let title = await self.importAttachment(attachment: attachment, disposition: disposition)
            // TODO: - Manage inline attachment
            return title
        }

        attachmentsTitles = titles
    }

    public func removeAttachment(_ attachmentUUID: String) async {
        try? writeTransaction { writableRealm in
            guard let draftInContext = writableRealm.object(ofType: Draft.self, forPrimaryKey: self.draftLocalUUID) else {
                return
            }

            guard let liveAttachment = draftInContext.attachments.first(where: { $0.uuid == attachmentUUID }) else {
                return
            }

            writableRealm.delete(liveAttachment)
        }

        await attachmentUploadTasks[attachmentUUID]?.task?.cancel()
        attachmentUploadTasks.removeValue(forKey: attachmentUUID)

        await updateDelegate?.contentWillChange()
    }

    public func completeUploadedAttachments() async {
        for attachment in detachedAttachments {
            let uploadTask = await attachmentUploadTaskOrCreate(for: attachment.uuid)
            await updateAttachmentUploadTaskProgress(uploadTask, progress: 1)
        }
        await updateDelegate?.contentWillChange()
    }

    public func processHTMLAttachments(_ htmlAttachments: [HTMLAttachable], draftContentManager: DraftContentManager) async {
        // Get first usable title
        let anyUsableTitle = await anyUsableTitle(in: htmlAttachments)

        // Get all the sanitized HTML we can fetch
        let allSanitizedHtmlString = await allSanitizedHtml(in: htmlAttachments).joined(separator: "")

        // Mutate Draft
        try? writeTransaction { writableRealm in
            guard let draftInContext = writableRealm.object(ofType: Draft.self, forPrimaryKey: self.draftLocalUUID) else {
                return
            }

            // Title if any usable
            var modified = false
            if draftInContext.subject.isEmpty,
               !anyUsableTitle.isEmpty {
                draftInContext.subject = anyUsableTitle
                modified = true
            }

            if !allSanitizedHtmlString.isEmpty {
                draftInContext.body = allSanitizedHtmlString + draftInContext.body
                modified = true
            }

            guard modified else {
                return
            }

            writableRealm.add(draftInContext, update: .modified)
        }

        await draftContentManager.refreshFromExternalEvent()
    }

    private func anyUsableTitle(in textAttachments: [TextAttachable]) async -> String {
        let textAttachments = await textAttachments.asyncMap { attachment in
            await attachment.textAttachment
        }

        let title = textAttachments.first { $0.title?.isEmpty == false }?.title ?? ""
        return title
    }

    private func allSanitizedHtml(in htmlAttachments: [HTMLAttachable]) async -> [String] {
        let allSanitizedHtml: [String] = await htmlAttachments.asyncCompactMap { attachment in
            guard let renderedHTML = await attachment.renderedHTML,
                  !renderedHTML.isEmpty else {
                return nil
            }

            return renderedHTML
        }

        return allSanitizedHtml
    }

    @MainActor public func attachmentUploadTaskOrFinishedTask(for uuid: String) -> AttachmentTask {
        guard let attachment = attachmentUploadTask(for: uuid) else {
            let finishedTask = AttachmentTask()
            updateAttachmentUploadTaskProgress(finishedTask, progress: 1)
            attachmentUploadTasks[uuid] = finishedTask
            return finishedTask
        }

        return attachment
    }
}

// MARK: - Naming helpers

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
