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

import Alamofire
import Foundation
import InfomaniakCore
import InfomaniakLogin

/// implementing `MailApiExtendedFetchable`
public extension MailApiFetcher {
    func permissions(mailbox: Mailbox) async throws -> MailboxPermissions {
        try await perform(request: authenticatedRequest(.permissions(mailbox: mailbox))).data
    }

    func contacts() async throws -> [InfomaniakContact] {
        try await perform(request: authenticatedRequest(.contacts)).data
    }

    func addressBooks() async throws -> AddressBookResult {
        try await perform(request: authenticatedRequest(.addressBooks)).data
    }

    func addContact(_ recipient: Recipient, to addressBook: AddressBook) async throws -> Int {
        try await perform(request: authenticatedSession.request(Endpoint.addContact.url,
                                                                method: .post,
                                                                parameters: NewContact(from: recipient, addressBook: addressBook),
                                                                encoder: JSONParameterEncoder.default)).data
    }

    func signatures(mailbox: Mailbox) async throws -> SignatureResponse {
        try await perform(request: authenticatedRequest(.signatures(hostingId: mailbox.hostingId, mailboxName: mailbox.mailbox)))
            .data
    }

    func updateSignature(mailbox: Mailbox, signature: Signature) async throws -> Bool {
        try await perform(request:
            authenticatedRequest(
                .updateSignature(
                    hostingId: mailbox.hostingId,
                    mailboxName: mailbox.mailbox,
                    signatureId: signature.id
                ),
                method: .patch,
                parameters: signature
            )).data
    }

    func folders(mailbox: Mailbox) async throws -> [Folder] {
        try await perform(request: authenticatedRequest(.folders(uuid: mailbox.uuid))).data
    }

    func flushFolder(mailbox: Mailbox, folderId: String) async throws -> Bool {
        try await perform(request: authenticatedRequest(.flushFolder(mailboxUuid: mailbox.uuid, folderId: folderId),
                                                        method: .post)).data
    }

    func markAsSeen(mailbox: Mailbox, messages: [Message]) async throws -> MessageActionResult {
        try await perform(request: authenticatedRequest(.messageSeen(uuid: mailbox.uuid),
                                                        method: .post,
                                                        parameters: ["uids": messages.map(\.uid)])).data
    }

    func markAsUnseen(mailbox: Mailbox, messages: [Message]) async throws -> MessageActionResult {
        try await perform(request: authenticatedRequest(.messageUnseen(uuid: mailbox.uuid),
                                                        method: .post,
                                                        parameters: ["uids": messages.map(\.uid)])).data
    }

    func move(mailbox: Mailbox, messages: [Message], destinationId: String) async throws -> UndoResponse {
        try await perform(request: authenticatedRequest(.moveMessages(uuid: mailbox.uuid),
                                                        method: .post,
                                                        parameters: ["uids": messages.map(\.uid), "to": destinationId])).data
    }

    func delete(mailbox: Mailbox, messages: [Message]) async throws -> Empty {
        try await perform(request: authenticatedRequest(.deleteMessages(uuid: mailbox.uuid),
                                                        method: .post,
                                                        parameters: ["uids": messages.map(\.uid)])).data
    }

    func attachment(attachment: Attachment) async throws -> Data {
        guard let resource = attachment.resource else {
            throw MailError.resourceError
        }
        let request = authenticatedRequest(.resource(resource))
        return try await request.serializingData().value
    }

    func messagesUids(
        mailboxUuid: String,
        folderId: String,
        paginationInfo: PaginationInfo? = nil
    ) async throws -> MessageUidsResult {
        try await perform(request: authenticatedRequest(.messagesUids(
            mailboxUuid: mailboxUuid,
            folderId: folderId,
            paginationInfo: paginationInfo
        ))).data
    }

    func messagesByUids(mailboxUuid: String, folderId: String, messageUids: [String]) async throws -> MessageByUidsResult {
        try await perform(request: authenticatedRequest(.messagesByUids(
            mailboxUuid: mailboxUuid,
            folderId: folderId,
            messagesUids: messageUids
        ))).data
    }

    func messagesDelta(mailboxUUid: String, folderId: String, signature: String) async throws -> MessageDeltaResult {
        try await perform(request: authenticatedRequest(.messagesDelta(
            mailboxUuid: mailboxUUid,
            folderId: folderId,
            signature: signature
        ))).data
    }

    func message(message: Message) async throws -> Message {
        try await perform(request: authenticatedRequest(.resource(
            message.resource,
            queryItems: [
                URLQueryItem(name: "prefered_format", value: "html")
            ]
        ))).data
    }

    func draft(mailbox: Mailbox, draftUuid: String) async throws -> Draft {
        try await perform(request: authenticatedRequest(.draft(uuid: mailbox.uuid, draftUuid: draftUuid))).data
    }

    func draft(from message: Message) async throws -> Draft {
        guard let resource = message.draftResource else {
            throw MailError.resourceError
        }
        return try await perform(request: authenticatedRequest(.resource(resource))).data
    }

    func send(mailbox: Mailbox, draft: Draft) async throws -> SendResponse {
        try await perform(request: authenticatedRequest(
            draft.remoteUUID.isEmpty ? .draft(uuid: mailbox.uuid) : .draft(uuid: mailbox.uuid, draftUuid: draft.remoteUUID),
            method: draft.remoteUUID.isEmpty ? .post : .put,
            parameters: draft
        )).data
    }

    func save(mailbox: Mailbox, draft: Draft) async throws -> DraftResponse {
        try await perform(request: authenticatedRequest(
            draft.remoteUUID.isEmpty ? .draft(uuid: mailbox.uuid) : .draft(uuid: mailbox.uuid, draftUuid: draft.remoteUUID),
            method: draft.remoteUUID.isEmpty ? .post : .put,
            parameters: draft
        )).data
    }

    @discardableResult
    func deleteDraft(mailbox: Mailbox, draftId: String) async throws -> Empty? {
        // TODO: Remove try? when bug will be fixed from API
        return try? await perform(request: authenticatedRequest(.draft(uuid: mailbox.uuid, draftUuid: draftId), method: .delete))
            .data
    }

    @discardableResult
    func deleteDraft(draftResource: String) async throws -> Empty? {
        // TODO: Remove try? when bug will be fixed from API
        return try? await perform(request: authenticatedRequest(.resource(draftResource), method: .delete)).data
    }
}
