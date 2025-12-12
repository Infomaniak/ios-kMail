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

import Alamofire
import Foundation
import InfomaniakCore
import InfomaniakLogin

/// implementing `MailApiExtendedFetchable`
public extension MailApiFetcher {
    func permissions(mailbox: Mailbox) async throws -> MailboxPermissions {
        try await perform(request: authenticatedRequest(.permissions(mailbox: mailbox)))
    }

    func sendersRestrictions(mailbox: Mailbox) async throws -> SendersRestrictions {
        try await perform(request: authenticatedRequest(.sendersRestrictions(mailbox: mailbox)))
    }

    func updateSendersRestrictions(mailbox: Mailbox, sendersRestrictions: SendersRestrictions) async throws -> Bool {
        try await perform(request: authenticatedRequest(
            .mailHosting(mailbox: mailbox),
            method: .patch,
            parameters: sendersRestrictions
        ))
    }

    func updateSpamFilter(mailbox: Mailbox, value: Bool) async throws -> Bool {
        let encodedParameters = ["has_move_spam": value]
        return try await perform(request: authenticatedRequest(
            .mailHosting(mailbox: mailbox),
            method: .patch,
            parameters: encodedParameters
        ))
    }

    func featureFlag(_ mailboxUUID: String) async throws -> [FeatureFlag] {
        try await perform(request: authenticatedRequest(.featureFlag(mailboxUUID)))
    }

    func contacts() async throws -> [InfomaniakContact] {
        try await perform(request: authenticatedRequest(.contacts))
    }

    func addressBooks() async throws -> AddressBookResult {
        try await perform(request: authenticatedRequest(.addressBooks))
    }

    func addContact(_ recipient: Recipient, to addressBook: AddressBook) async throws -> Int {
        try await perform(request: authenticatedSession.request(Endpoint.addContact.url,
                                                                method: .post,
                                                                parameters: NewContact(from: recipient, addressBook: addressBook),
                                                                encoder: JSONParameterEncoder.default))
    }

    func signatures(mailbox: Mailbox) async throws -> SignatureResponse {
        try await perform(request: authenticatedRequest(.signatures(hostingId: mailbox.hostingId, mailboxName: mailbox.mailbox)))
    }

    @discardableResult
    func updateSignature(mailbox: Mailbox, signature: Signature?) async throws -> Bool {
        try await perform(request:
            authenticatedRequest(
                .updateSignature(
                    hostingId: mailbox.hostingId,
                    mailboxName: mailbox.mailbox
                ),
                method: .post,
                parameters: ["default_signature_id": signature?.id]
            ))
    }

    func folders(mailbox: Mailbox) async throws -> [Folder] {
        try await perform(request: authenticatedRequest(.folders(uuid: mailbox.uuid)))
    }

    func flushFolder(mailbox: Mailbox, folderId: String) async throws -> Bool {
        try await perform(request: authenticatedRequest(.flushFolder(mailboxUuid: mailbox.uuid, folderId: folderId),
                                                        method: .post))
    }

    @discardableResult
    func markAsSeen(mailbox: Mailbox, messages: [Message]) async throws -> MessageActionResult {
        try await perform(request: authenticatedRequest(.messageSeen(uuid: mailbox.uuid),
                                                        method: .post,
                                                        parameters: ["uids": messages.map(\.uid)]))
    }

    @discardableResult
    func markAsUnseen(mailbox: Mailbox, messages: [Message]) async throws -> MessageActionResult {
        try await perform(request: authenticatedRequest(.messageUnseen(uuid: mailbox.uuid),
                                                        method: .post,
                                                        parameters: ["uids": messages.map(\.uid)]))
    }

    func move(mailboxUuid: String, messages: [Message], destinationId: String,
              alsoMoveReactions: Bool) async throws -> UndoResponse {
        try await perform(request: authenticatedRequest(.moveMessages(uuid: mailboxUuid, alsoMoveReactions: alsoMoveReactions),
                                                        method: .post,
                                                        parameters: [
                                                            "uids": messages.map(\.uid),
                                                            "to": destinationId
                                                        ]))
    }

    @discardableResult
    func delete(mailbox: Mailbox, messages: [Message], alsoMoveReactions: Bool) async throws -> [Empty] {
        try await batchOver(values: messages.map(\.uid), chunkSize: Constants.apiLimit) { chunk in
            try await self.perform(request: self.authenticatedRequest(
                .deleteMessages(uuid: mailbox.uuid, alsoMoveReactions: alsoMoveReactions),
                method: .post,
                parameters: ["uids": chunk]
            ))
        }
    }

    func messagesUids(mailboxUuid: String, folderId: String) async throws -> MessageUidsResult {
        try await perform(request: authenticatedRequest(.messagesUids(mailboxUuid: mailboxUuid, folderId: folderId)))
    }

    func messagesByUids(mailboxUuid: String, folderId: String, messageUids: [String]) async throws -> MessageByUidsResult {
        try await perform(request: authenticatedRequest(.messagesByUids(
            mailboxUuid: mailboxUuid,
            folderId: folderId,
            messagesUids: messageUids
        )))
    }

    func messagesDelta<Flags: DeltaFlags>(mailboxUuid: String, folderId: String,
                                          signature: String, uids: String? = nil) async throws -> MessagesDelta<Flags> {
        let method = uids == nil ? HTTPMethod.get : HTTPMethod.post
        return try await perform(request: authenticatedRequest(.messagesDelta(
                mailboxUuid: mailboxUuid,
                folderId: folderId,
                signature: signature
            ),
            method: method,
            parameters: uids))
    }

    func message(message: Message) async throws -> Message {
        try await perform(request: authenticatedRequest(.resource(
            message.resource,
            queryItems: [
                URLQueryItem(name: "prefered_format", value: "html"),
                URLQueryItem(name: "with", value: "auto_uncrypt,recipient_provider_source,emoji_reactions_per_message")
            ]
        )))
    }

    func draft(mailbox: Mailbox, draftUuid: String) async throws -> Draft {
        try await perform(request: authenticatedRequest(.draft(uuid: mailbox.uuid, draftUuid: draftUuid)))
    }

    func draft(from message: Message) async throws -> Draft {
        guard let resource = message.draftResource else {
            throw MailError.resourceError
        }
        return try await perform(request: authenticatedRequest(.resource(resource)))
    }

    func draft(draftResource: String) async throws -> Draft {
        return try await perform(request: authenticatedRequest(.resource(draftResource)))
    }

    func send<T: Decodable>(mailbox: Mailbox, draft: Draft) async throws -> T {
        try await perform(request: authenticatedRequest(
            draft.remoteUUID.isEmpty ? .draft(uuid: mailbox.uuid) : .draft(uuid: mailbox.uuid, draftUuid: draft.remoteUUID),
            method: draft.remoteUUID.isEmpty ? .post : .put,
            parameters: draft
        ))
    }

    @discardableResult
    func deleteDraft(mailbox: Mailbox, draftId: String) async throws -> Empty? {
        // TODO: Remove try? when bug will be fixed from API
        return try? await perform(request: authenticatedRequest(.draft(uuid: mailbox.uuid, draftUuid: draftId), method: .delete))
    }

    @discardableResult
    func deleteDraft(draftResource: String) async throws -> Empty? {
        // TODO: Remove try? when bug will be fixed from API
        return try? await perform(request: authenticatedRequest(.resource(draftResource), method: .delete))
    }

    func changeDraftSchedule(draftResource: String, scheduleDate: Date) async throws {
        let _: Empty = try await perform(request: authenticatedRequest(
            .draftSchedule(draftAction: draftResource.appending("/schedule")),
            method: .put,
            parameters: ["schedule_date": scheduleDate]
        ))
    }

    func deleteSchedule(scheduleAction: String) async throws {
        let _: Empty = try await perform(request: authenticatedRequest(
            .draftSchedule(draftAction: scheduleAction),
            method: .delete
        ))
    }

    func lastSyncDate() async throws -> String? {
        return try await perform(request: authenticatedRequest(.lastSyncDate))
    }

    func mailHosted(for recipients: [String]) async throws -> [MailHosted] {
        return try await perform(request: authenticatedRequest(.mailHosted(for: recipients)))
    }

    func unsubscribe(messageResource: String) async throws {
        let _: Empty = try await perform(request: authenticatedRequest(.unsubscribe(resource: messageResource), method: .post))
    }

    func acknowledgeMessage(messageResource: String) async throws {
        let _: Empty = try await perform(request: authenticatedRequest(.acknowledge(resource: messageResource), method: .get))
    }
}
