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
import InfomaniakConcurrency
import InfomaniakCore
import InfomaniakLogin

/// implementing `MailApiCommonFetchable`
public extension MailApiFetcher {
    // MARK: - API methods

    func mailboxes() async throws -> [Mailbox] {
        try await perform(request: authenticatedRequest(.mailboxes))
    }

    func listBackups(mailbox: Mailbox) async throws -> BackupsList {
        try await perform(request: authenticatedRequest(.backups(hostingId: mailbox.hostingId, mailboxName: mailbox.mailbox)))
    }

    @discardableResult
    func restoreBackup(mailbox: Mailbox, date: String) async throws -> Bool {
        try await perform(request: authenticatedRequest(.backups(hostingId: mailbox.hostingId, mailboxName: mailbox.mailbox),
                                                        method: .put,
                                                        parameters: ["date": date]))
    }

    func threads(mailbox: Mailbox, folderId: String, filter: Filter = .all,
                 searchFilter: [URLQueryItem] = [], isDraftFolder: Bool = false) async throws -> ThreadResult {
        try await perform(request: authenticatedRequest(.threads(
            uuid: mailbox.uuid,
            folderId: folderId,
            filter: filter == .all ? nil : filter.rawValue,
            searchFilters: searchFilter,
            isDraftFolder: isDraftFolder
        )))
    }

    func threads(from resource: String, searchFilter: [URLQueryItem] = []) async throws -> ThreadResult {
        try await perform(request: authenticatedRequest(.resource(resource, queryItems: searchFilter)))
    }

    func download(messages: [Message]) async throws -> [URL] {
        let temporaryDirectory = FileManager.default.temporaryDirectory

        return try await messages.concurrentMap { message in
            let directoryURL = temporaryDirectory.appendingPathComponent(message.uid, isDirectory: true)
            let destination: DownloadRequest.Destination = { _, response in
                (
                    directoryURL.appendingPathComponent(response.suggestedFilename!),
                    [.createIntermediateDirectories, .removePreviousFile]
                )
            }

            let download = self.authenticatedSession.download(Endpoint.resource(message.downloadResource).url, to: destination)
            let messageUrl = try await download.serializingDownloadedFileURL().value
            return messageUrl
        }
    }

    func quotas(mailbox: Mailbox) async throws -> Quotas {
        try await perform(request: authenticatedRequest(.quotas(mailbox: mailbox.mailbox, productId: mailbox.hostingId)))
    }

    func externalMailFlag(mailbox: Mailbox) async throws -> ExternalMailInfo {
        try await perform(request: authenticatedRequest(.externalMailFlag(
            hostingId: mailbox.hostingId,
            mailboxName: mailbox.mailbox
        )))
    }

    @discardableResult
    func undoAction(resource: String) async throws -> Bool {
        try await perform(request: authenticatedRequest(.resource(resource), method: .post))
    }

    @discardableResult
    func star(mailbox: Mailbox, messages: [Message]) async throws -> MessageActionResult {
        try await perform(request: authenticatedRequest(.star(uuid: mailbox.uuid),
                                                        method: .post,
                                                        parameters: ["uids": messages.map(\.uid)]))
    }

    @discardableResult
    func unstar(mailbox: Mailbox, messages: [Message]) async throws -> MessageActionResult {
        try await perform(request: authenticatedRequest(.unstar(uuid: mailbox.uuid),
                                                        method: .post,
                                                        parameters: ["uids": messages.map(\.uid)]))
    }

    @discardableResult
    func blockSender(message: Message) async throws -> NullableResponse {
        try await perform(request: authenticatedRequest(.blockSender(messageResource: message.resource), method: .post))
    }

    func reportPhishing(message: Message) async throws -> Bool {
        try await perform(request: authenticatedRequest(.report(messageResource: message.resource),
                                                        method: .post,
                                                        parameters: ["type": "phishing"]))
    }

    func reportSpams(mailboxUuid: String, messages: [Message]) async throws -> UndoResponse {
        try await perform(request: authenticatedRequest(
            .spam(uuid: mailboxUuid),
            method: .post,
            parameters: ["uids": messages.map(\.uid)]
        ))
    }

    func create(mailbox: Mailbox, folder: NewFolder) async throws -> Folder {
        try await perform(request: authenticatedRequest(.folders(uuid: mailbox.uuid), method: .post, parameters: folder))
    }

    @discardableResult
    func delete(mailbox: Mailbox, folder: Folder) async throws -> Empty? {
        try await perform(request: authenticatedRequest(
            .folder(uuid: mailbox.uuid, folderUUID: folder.remoteId),
            method: .delete
        ))
    }

    func modify(mailbox: Mailbox, folder: Folder, name: String) async throws -> Folder {
        return try await perform(request: authenticatedRequest(
            .modifyFolder(mailboxUuid: mailbox.uuid, folderId: folder.remoteId),
            method: .post,
            parameters: ["name": name]
        ))
    }

    func createAttachment(
        mailbox: Mailbox,
        attachmentData: Data,
        attachment: Attachment,
        progressObserver: @escaping (Double) -> Void
    ) async throws -> Attachment {
        let headers = HTTPHeaders([
            "x-ws-attachment-filename": attachment.name,
            "x-ws-attachment-mime-type": attachment.mimeType,
            "x-ws-attachment-disposition": attachment.disposition.rawValue
        ])
        var request = try URLRequest(url: Endpoint.createAttachment(uuid: mailbox.uuid).url, method: .post, headers: headers)
        request.httpBody = attachmentData

        let uploadRequest = authenticatedSession.request(request)
        Task {
            for await progress in uploadRequest.uploadProgress() {
                progressObserver(progress.fractionCompleted)
            }
        }

        return try await perform(request: uploadRequest)
    }

    func attachmentsToForward(mailbox: Mailbox, message: Message) async throws -> AttachmentsToForwardResult {
        let attachmentsToForward = AttachmentsToForward(toForwardUids: [message.uid], mode: AttachmentDisposition.inline.rawValue)
        return try await perform(request: authenticatedRequest(.attachmentToForward(uuid: mailbox.uuid),
                                                               method: .post,
                                                               parameters: attachmentsToForward))
    }

    func shareMailLink(message: Message) async throws -> ShareMailLinkResult {
        try await perform(request: authenticatedRequest(.share(messageResource: message.resource),
                                                        method: .post))
    }
}
