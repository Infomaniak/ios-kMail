//
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
import Alamofire

/// Something that makes sure network calls of a specific `MailApiFetcher` are treated in a serial manner
public struct MailApiFetcherSerializer: MailApiFetchable {
    /// Serialize API Calls
    private let taskQueue = TaskQueue(concurrency: 1)

    private let mailApiFetcher: MailApiFetcher

    public init(mailApiFetcher: MailApiFetcher) {
        self.mailApiFetcher = mailApiFetcher
    }

    // MARK: - MailApiFetchable

    public func mailboxes() async throws -> [Mailbox] {
        try await taskQueue.enqueue {
            try await mailApiFetcher.mailboxes()
        }
    }

    public func addMailbox(mail: String, password: String) async throws -> MailboxLinkedResult {
        try await taskQueue.enqueue {
            try await mailApiFetcher.addMailbox(mail: mail, password: password)
        }
    }

    public func updateMailboxPassword(mailbox: Mailbox, password: String) async throws -> Bool {
        try await taskQueue.enqueue {
            try await mailApiFetcher.updateMailboxPassword(mailbox: mailbox, password: password)
        }
    }

    public func detachMailbox(mailbox: Mailbox) async throws -> Bool {
        try await taskQueue.enqueue {
            try await mailApiFetcher.detachMailbox(mailbox: mailbox)
        }
    }

    public func listBackups(mailbox: Mailbox) async throws -> BackupsList {
        try await taskQueue.enqueue {
            try await mailApiFetcher.listBackups(mailbox: mailbox)
        }
    }

    public func restoreBackup(mailbox: Mailbox, date: String) async throws -> Bool {
        try await taskQueue.enqueue {
            try await mailApiFetcher.restoreBackup(mailbox: mailbox, date: date)
        }
    }

    public func threads(
        mailbox: Mailbox,
        folderId: String,
        filter: Filter,
        searchFilter: [URLQueryItem],
        isDraftFolder: Bool
    ) async throws -> ThreadResult {
        try await taskQueue.enqueue {
            try await mailApiFetcher.threads(
                mailbox: mailbox,
                folderId: folderId,
                filter: filter,
                searchFilter: searchFilter,
                isDraftFolder: isDraftFolder
            )
        }
    }

    public func threads(from resource: String, searchFilter: [URLQueryItem]) async throws -> ThreadResult {
        try await taskQueue.enqueue {
            try await mailApiFetcher.threads(from: resource, searchFilter: searchFilter)
        }
    }

    public func download(message: Message) async throws -> URL {
        try await taskQueue.enqueue {
            try await mailApiFetcher.download(message: message)
        }
    }

    public func quotas(mailbox: Mailbox) async throws -> Quotas {
        try await taskQueue.enqueue {
            try await mailApiFetcher.quotas(mailbox: mailbox)
        }
    }

    public func undoAction(resource: String) async throws -> Bool {
        try await taskQueue.enqueue {
            try await mailApiFetcher.undoAction(resource: resource)
        }
    }

    public func star(mailbox: Mailbox, messages: [Message]) async throws -> MessageActionResult {
        try await taskQueue.enqueue {
            try await mailApiFetcher.star(mailbox: mailbox, messages: messages)
        }
    }

    public func unstar(mailbox: Mailbox, messages: [Message]) async throws -> MessageActionResult {
        try await taskQueue.enqueue {
            try await mailApiFetcher.unstar(mailbox: mailbox, messages: messages)
        }
    }

    public func downloadAttachments(message: Message) async throws -> URL {
        try await taskQueue.enqueue {
            try await mailApiFetcher.downloadAttachments(message: message)
        }
    }

    public func blockSender(message: Message) async throws -> Bool {
        try await taskQueue.enqueue {
            try await mailApiFetcher.blockSender(message: message)
        }
    }

    public func reportPhishing(message: Message) async throws -> Bool {
        try await taskQueue.enqueue {
            try await mailApiFetcher.reportPhishing(message: message)
        }
    }

    public func create(mailbox: Mailbox, folder: NewFolder) async throws -> Folder {
        try await taskQueue.enqueue {
            try await mailApiFetcher.create(mailbox: mailbox, folder: folder)
        }
    }

    public func createAttachment(
        mailbox: Mailbox,
        attachmentData: Data,
        attachment: Attachment,
        progressObserver: @escaping (Double) -> Void
    ) async throws -> Attachment {
        try await taskQueue.enqueue {
            try await mailApiFetcher.createAttachment(
                mailbox: mailbox,
                attachmentData: attachmentData,
                attachment: attachment,
                progressObserver: progressObserver
            )
        }
    }

    public func attachmentsToForward(mailbox: Mailbox, message: Message) async throws -> AttachmentsToForwardResult {
        try await taskQueue.enqueue {
            try await mailApiFetcher.attachmentsToForward(mailbox: mailbox, message: message)
        }
    }

    public func permissions(mailbox: Mailbox) async throws -> MailboxPermissions {
        try await taskQueue.enqueue {
            try await mailApiFetcher.permissions(mailbox: mailbox)
        }
    }

    public func contacts() async throws -> [Contact] {
        try await taskQueue.enqueue {
            try await mailApiFetcher.contacts()
        }
    }

    public func addressBooks() async throws -> AddressBookResult {
        try await taskQueue.enqueue {
            try await mailApiFetcher.addressBooks()
        }
    }

    public func addContact(_ recipient: Recipient, to addressBook: AddressBook) async throws -> Int {
        try await taskQueue.enqueue {
            try await mailApiFetcher.addContact(recipient, to: addressBook)
        }
    }

    public func signatures(mailbox: Mailbox) async throws -> SignatureResponse {
        try await taskQueue.enqueue {
            try await mailApiFetcher.signatures(mailbox: mailbox)
        }
    }

    public func updateSignature(mailbox: Mailbox, signature: Signature) async throws -> Bool {
        try await taskQueue.enqueue {
            try await mailApiFetcher.updateSignature(mailbox: mailbox, signature: signature)
        }
    }

    public func folders(mailbox: Mailbox) async throws -> [Folder] {
        try await taskQueue.enqueue {
            try await mailApiFetcher.folders(mailbox: mailbox)
        }
    }

    public func flushFolder(mailbox: Mailbox, folderId: String) async throws -> Bool {
        try await taskQueue.enqueue {
            try await mailApiFetcher.flushFolder(mailbox: mailbox, folderId: folderId)
        }
    }

    public func messagesUids(mailboxUuid: String, folderId: String,
                             paginationInfo: PaginationInfo?) async throws -> MessageUidsResult {
        try await taskQueue.enqueue {
            try await mailApiFetcher.messagesUids(mailboxUuid: mailboxUuid, folderId: folderId, paginationInfo: paginationInfo)
        }
    }

    public func messagesByUids(mailboxUuid: String, folderId: String, messageUids: [String]) async throws -> MessageByUidsResult {
        try await taskQueue.enqueue {
            try await mailApiFetcher.messagesByUids(mailboxUuid: mailboxUuid, folderId: folderId, messageUids: messageUids)
        }
    }

    public func messagesDelta(mailboxUUid: String, folderId: String, signature: String) async throws -> MessageDeltaResult {
        try await taskQueue.enqueue {
            try await mailApiFetcher.messagesDelta(mailboxUUid: mailboxUUid, folderId: folderId, signature: signature)
        }
    }

    public func message(message: Message) async throws -> Message {
        try await taskQueue.enqueue {
            try await mailApiFetcher.message(message: message)
        }
    }

    public func markAsSeen(mailbox: Mailbox, messages: [Message]) async throws -> MessageActionResult {
        try await taskQueue.enqueue {
            try await mailApiFetcher.markAsSeen(mailbox: mailbox, messages: messages)
        }
    }

    public func markAsUnseen(mailbox: Mailbox, messages: [Message]) async throws -> MessageActionResult {
        try await taskQueue.enqueue {
            try await mailApiFetcher.markAsUnseen(mailbox: mailbox, messages: messages)
        }
    }

    public func move(mailbox: Mailbox, messages: [Message], destinationId: String) async throws -> UndoResponse {
        try await taskQueue.enqueue {
            try await mailApiFetcher.move(mailbox: mailbox, messages: messages, destinationId: destinationId)
        }
    }

    public func delete(mailbox: Mailbox, messages: [Message]) async throws -> Alamofire.Empty {
        try await taskQueue.enqueue {
            try await mailApiFetcher.delete(mailbox: mailbox, messages: messages)
        }
    }

    public func attachment(attachment: Attachment) async throws -> Data {
        try await taskQueue.enqueue {
            try await mailApiFetcher.attachment(attachment: attachment)
        }
    }

    public func draft(mailbox: Mailbox, draftUuid: String) async throws -> Draft {
        try await taskQueue.enqueue {
            try await mailApiFetcher.draft(mailbox: mailbox, draftUuid: draftUuid)
        }
    }

    public func draft(from message: Message) async throws -> Draft {
        try await taskQueue.enqueue {
            try await mailApiFetcher.draft(from: message)
        }
    }

    public func send(mailbox: Mailbox, draft: Draft) async throws -> SendResponse {
        try await taskQueue.enqueue {
            try await mailApiFetcher.send(mailbox: mailbox, draft: draft)
        }
    }

    public func save(mailbox: Mailbox, draft: Draft) async throws -> DraftResponse {
        try await taskQueue.enqueue {
            try await mailApiFetcher.save(mailbox: mailbox, draft: draft)
        }
    }

    public func deleteDraft(mailbox: Mailbox, draftId: String) async throws -> Alamofire.Empty? {
        try await taskQueue.enqueue {
            try await mailApiFetcher.deleteDraft(mailbox: mailbox, draftId: draftId)
        }
    }

    public func deleteDraft(draftResource: String) async throws -> Alamofire.Empty? {
        try await taskQueue.enqueue {
            try await mailApiFetcher.deleteDraft(draftResource: draftResource)
        }
    }
}
