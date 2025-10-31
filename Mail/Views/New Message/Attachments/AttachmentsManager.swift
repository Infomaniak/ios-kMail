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
import PhotosUI
import SwiftUI

/// Something to deal with the tracking and Upload of Attachments linked to a Draft.
/// periphery:ignore - AttachmentsManageable is needed in case we later want to do tests
@MainActor protocol AttachmentsManageable {
    /// Live Attachments linked to the Draft
    var liveAttachments: [Attachment] { get }

    /// True if all uploaded
    var allAttachmentsUploaded: Bool { get }

    /// First error encountered
    var globalError: LocalError? { get }

    /// Init a concrete manager type
    /// - Parameters:
    ///   - draftLocalUUID: the primary key of the draft
    ///   - mailboxManager: the mailbox manager linked to this draft
    init(draftLocalUUID: String, mailboxManager: MailboxManager)

    /// Marks all uploads as done
    func completeUploadedAttachments() async

    /// Lookup and return _or_ new object representing a finished task instead.
    func attachmentUploadTaskOrFinishedTask(for uuid: String) -> AttachmentTask

    /// Removes an attachment for a specific primary key
    /// - Parameter attachmentUUID: primary key of the object
    func removeAttachment(_ attachmentUUID: String)

    /// Uploads remotely a collection of `Attachable`
    /// - Parameters:
    ///   - attachments: collection of `Attachable`
    ///   - draft: Draft containing the attachments
    ///   - disposition: Is it inline ?
    func importAttachments(attachments: [Attachable], draft: Draft, disposition: AttachmentDisposition)
}

/// Something to track `Attachments` linked to a live `Draft`
/// periphery:ignore - AttachmentsManageable is needed in case we later want to do tests
@MainActor final class AttachmentsManager: ObservableObject, AttachmentsManageable {
    /// Async attachment operations
    private let worker: AttachmentsManagerWorker

    /// Something to debounce content will change updates
    private let contentWillChangeSubject = PassthroughSubject<Void, Never>()
    private var contentWillChangeObserver: AnyCancellable?

    var liveAttachments: [Attachment] {
        worker.liveAttachments
    }

    var allAttachmentsUploaded: Bool {
        worker.allAttachmentsUploaded
    }

    var globalError: LocalError?

    init(draftLocalUUID: String, mailboxManager: MailboxManager) {
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

    func removeAttachment(_ attachmentUUID: String) {
        Task {
            await worker.removeAttachment(attachmentUUID)
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

    func handleGlobalError(_ error: LocalError) {
        globalError = error
    }
}
