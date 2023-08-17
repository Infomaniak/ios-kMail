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
import Alamofire
import InfomaniakCore

/// Public interface of `MailApiFetcher`
public typealias MailApiFetchable = MailApiCommonFetchable & MailApiExtendedFetchable

/// Main interface of the `MailApiFetcher`
public protocol MailApiCommonFetchable {
    func mailboxes() async throws -> [Mailbox]

    func addMailbox(mail: String, password: String) async throws -> MailboxLinkedResult

    func updateMailboxPassword(mailbox: Mailbox, password: String) async throws -> Bool

    func detachMailbox(mailbox: Mailbox) async throws -> Bool

    func listBackups(mailbox: Mailbox) async throws -> BackupsList

    func restoreBackup(mailbox: Mailbox, date: String) async throws -> Bool

    func threads(mailbox: Mailbox,
                 folderId: String,
                 filter: Filter,
                 searchFilter: [URLQueryItem],
                 isDraftFolder: Bool) async throws -> ThreadResult

    func threads(from resource: String, searchFilter: [URLQueryItem]) async throws -> ThreadResult

    func download(message: Message) async throws -> URL

    func quotas(mailbox: Mailbox) async throws -> Quotas

    func undoAction(resource: String) async throws -> Bool

    func star(mailbox: Mailbox, messages: [Message]) async throws -> MessageActionResult

    func unstar(mailbox: Mailbox, messages: [Message]) async throws -> MessageActionResult

    func downloadAttachments(message: Message) async throws -> URL

    func blockSender(message: Message) async throws -> NullableResponse

    func reportPhishing(message: Message) async throws -> Bool

    func create(mailbox: Mailbox, folder: NewFolder) async throws -> Folder

    func createAttachment(mailbox: Mailbox,
                          attachmentData: Data,
                          attachment: Attachment,
                          progressObserver: @escaping (Double) -> Void) async throws -> Attachment

    func attachmentsToForward(mailbox: Mailbox, message: Message) async throws -> AttachmentsToForwardResult
}

/// Extended capabilities of the `MailApiFetcher`
public protocol MailApiExtendedFetchable {
    
    func permissions(mailbox: Mailbox) async throws -> MailboxPermissions
    
    func contacts() async throws -> [Contact]
    
    func addressBooks() async throws -> AddressBookResult
    
    func addContact(_ recipient: Recipient, to addressBook: AddressBook) async throws -> Int
    
    func signatures(mailbox: Mailbox) async throws -> SignatureResponse
    
    func updateSignature(mailbox: Mailbox, signature: Signature) async throws -> Bool
    
    func folders(mailbox: Mailbox) async throws -> [Folder]
    
    func flushFolder(mailbox: Mailbox, folderId: String) async throws -> Bool
    
    func messagesUids(mailboxUuid: String,
                      folderId: String,
                      paginationInfo: PaginationInfo?) async throws -> MessageUidsResult
    
    func messagesByUids(mailboxUuid: String, folderId: String, messageUids: [String]) async throws -> MessageByUidsResult
    
    func messagesDelta(mailboxUUid: String, folderId: String, signature: String) async throws -> MessageDeltaResult
    
    func message(message: Message) async throws -> Message
    
    func markAsSeen(mailbox: Mailbox, messages: [Message]) async throws -> MessageActionResult
    
    func markAsUnseen(mailbox: Mailbox, messages: [Message]) async throws -> MessageActionResult
    
    func move(mailbox: Mailbox, messages: [Message], destinationId: String) async throws -> UndoResponse
    
    func delete(mailbox: Mailbox, messages: [Message]) async throws -> Empty
    
    func attachment(attachment: Attachment) async throws -> Data
    
    func draft(mailbox: Mailbox, draftUuid: String) async throws -> Draft
    
    func draft(from message: Message) async throws -> Draft
    
    func send(mailbox: Mailbox, draft: Draft) async throws -> SendResponse
    
    func save(mailbox: Mailbox, draft: Draft) async throws -> DraftResponse
    
    func deleteDraft(mailbox: Mailbox, draftId: String) async throws -> Empty?
    
    func deleteDraft(draftResource: String) async throws -> Empty?
}
