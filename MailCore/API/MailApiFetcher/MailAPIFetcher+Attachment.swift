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
    func attachment(attachment: Attachment, progressObserver: ((Double) -> Void)? = nil) async throws -> Data {
        guard let resource = attachment.resource else {
            throw MailError.resourceError
        }
        let request = authenticatedRequest(.resource(resource))
        if let progressObserver {
            Task {
                for await progress in request.downloadProgress() {
                    progressObserver(progress.fractionCompleted)
                }
            }
        }
        return try await request.serializingData().value
    }

    func downloadAttachments(message: Message, progressObserver: ((Double) -> Void)? = nil) async throws -> URL {
        try await downloadResource(
            endpoint: .downloadAttachments(messageResource: message.resource),
            progressObserver: progressObserver
        )
    }

    func swissTransferAttachment(stUuid: String) async throws -> SwissTransferAttachment {
        try await perform(request: authenticatedRequest(.swissTransfer(stUuid: stUuid)))
    }

    func downloadSwissTransferAttachment(stUuid: String, fileUuid: String,
                                         progressObserver: ((Double) -> Void)? = nil) async throws -> URL {
        try await downloadResource(
            endpoint: .downloadSwissTransferAttachment(stUuid: stUuid, fileUuid: fileUuid),
            progressObserver: progressObserver
        )
    }

    func downloadAllSwissTransferAttachment(stUuid: String, progressObserver: ((Double) -> Void)? = nil) async throws -> URL {
        try await downloadResource(
            endpoint: .downloadAllSwissTransferAttachments(stUuid: stUuid),
            progressObserver: progressObserver
        )
    }

    private func downloadResource(endpoint: Endpoint, progressObserver: ((Double) -> Void)? = nil) async throws -> URL {
        let destination = DownloadRequest.suggestedDownloadDestination(options: [
            .createIntermediateDirectories,
            .removePreviousFile
        ])
        let download = authenticatedSession.download(
            endpoint.url,
            to: destination
        )
        if let progressObserver {
            Task {
                for await progress in download.downloadProgress() {
                    progressObserver(progress.fractionCompleted)
                }
            }
        }
        return try await download.serializingDownloadedFileURL().value
    }
}
