/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import Combine
import Foundation
import InfomaniakCore
import MailCore
import MailCoreUI
import PhotosUI
import SwiftUI

@MainActor final class AttachmentsManager: ObservableObject {
    /// Async attachment operations
    private let worker: AttachmentsManagerWorker
    private let mailboxManager: MailboxManager
    private let draftLocalUUID: String

    /// Something to debounce content will change updates
    private let contentWillChangeSubject = PassthroughSubject<Void, Never>()
    private var contentWillChangeObserver: AnyCancellable?

    var attachments: [UIAttachment] {
        worker.liveAttachments.map {
            UIAttachment(
                attachment: $0,
                draftLocalUUID: draftLocalUUID,
                localURL: $0.getLocalURL(mailboxManager: mailboxManager)
            )
        }
    }

    var allAttachmentsUploaded: Bool {
        worker.allAttachmentsUploaded
    }

    var globalError: MailError?

    init(draftLocalUUID: String, mailboxManager: MailboxManager) {
        self.draftLocalUUID = draftLocalUUID
        self.mailboxManager = mailboxManager
        // Debouncing objectWillChange helps a lot scaling with numerous attachments
        worker = AttachmentsManagerWorker(draftLocalUUID: draftLocalUUID, mailboxManager: mailboxManager)

        contentWillChangeObserver = contentWillChangeSubject
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { _ in
                self.objectWillChange.send()
            }

        worker.setUpdateDelegate(self)
    }

    func completeUploadedAttachments() async {
        await worker.completeUploadedAttachments()
    }

    func processHTMLAttachments(_ attachments: [HTMLAttachable], draftContentManager: DraftContentManager) async {
        await worker.processHTMLAttachments(attachments, draftContentManager: draftContentManager)
    }

    func attachmentUploadTaskOrFinishedTask(for uuid: String) -> AttachmentTask {
        worker.attachmentUploadTaskOrFinishedTask(for: uuid)
    }

    func removeAttachment(_ attachment: UIAttachment) {
        guard let model = cachedAttachment(for: attachment) else {
            globalError = .resourceError
            objectWillChange.send()
            return
        }
        removeAttachment(model.uuid)
    }

    private func removeAttachment(_ attachmentUUID: String) {
        Task {
            await worker.removeAttachment(attachmentUUID)
        }
    }

    func removeInlineAttachment(contentId: String) {
        guard let attachment = worker.liveAttachments.first(where: { $0.contentId == contentId }) else { return }
        removeAttachment(attachment.uuid)
    }

    func saveAttachmentLocally(_ attachment: UIAttachment) async throws {
        guard let model = cachedAttachment(for: attachment) else {
            throw MailError.resourceError
        }
        try await mailboxManager.saveAttachmentLocally(attachment: model.freezeIfNeeded(), progressObserver: nil)
    }

    private func cachedAttachment(for attachment: UIAttachment) -> Attachment? {
        return worker.liveAttachments.first {
            UIAttachment.id(for: $0, draftLocalUUID: draftLocalUUID) == attachment.id
        }
    }

    func importAttachments(attachments: [Attachable], draft: Draft, disposition: AttachmentDisposition) {
        Task {
            await worker.importAttachments(attachments: attachments, draft: draft, disposition: disposition)
        }
    }
}

extension AttachmentsManager: AttachmentsContentUpdatable {
    func contentWillChange() {
        contentWillChangeSubject.send()
    }

    func handleGlobalError(_ error: MailError) {
        globalError = error
    }
}
