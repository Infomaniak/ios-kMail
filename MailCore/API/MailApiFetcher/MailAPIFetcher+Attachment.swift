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

import Alamofire
import Foundation
import InfomaniakCore

public extension MailApiFetcher {
    func attachment(attachment: Attachment) async throws -> Data {
        guard let resource = attachment.resource else {
            throw MailError.resourceError
        }
        let request = authenticatedRequest(.resource(resource))
        return try await request.serializingData().value
    }

    func downloadAttachments(message: Message) async throws -> URL {
        try await downloadResource(endpoint: .downloadAttachments(messageResource: message.resource))
    }

    func swissTransferAttachment(stUuid: String) async throws -> SwissTransferAttachment {
        try await perform(request: authenticatedRequest(.swissTransfer(stUuid: stUuid)))
    }

    func downloadSwissTransferAttachment(stUuid: String, fileUuid: String) async throws -> URL {
        try await downloadResource(endpoint: .downloadSwissTransferAttachment(stUuid: stUuid, fileUuid: fileUuid))
    }

    func downloadAllSwissTransferAttachment(stUuid: String) async throws -> URL {
        try await downloadResource(endpoint: .downloadAllSwissTransferAttachments(stUuid: stUuid))
    }

    private func downloadResource(endpoint: Endpoint) async throws -> URL {
        let destination = DownloadRequest.suggestedDownloadDestination(options: [
            .createIntermediateDirectories,
            .removePreviousFile
        ])
        let download = authenticatedSession.download(
            endpoint.url,
            to: destination
        )
        return try await download.serializingDownloadedFileURL().value
    }
}
