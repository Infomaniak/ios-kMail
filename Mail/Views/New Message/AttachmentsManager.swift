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
import MailCore
import PhotosUI
import SwiftUI

class AttachmentsManager: ObservableObject {
    private let draft: Draft
    private let mailboxManager: MailboxManager

    init(draft: Draft, mailboxManager: MailboxManager) {
        self.draft = draft
        self.mailboxManager = mailboxManager
    }

    @MainActor
    private func addAttachment(_ attachment: Attachment) {
        try? draft.realm?.write {
            draft.attachments.append(attachment)
        }
    }

    @MainActor
    func removeAttachment(_ attachment: Attachment) {
        if let attachmentToRemove = draft.attachments.firstIndex(where: { $0.uuid == attachment.uuid }) {
            try? draft.realm?.write {
                draft.attachments.remove(at: attachmentToRemove)
            }
        }
    }

    func addDocumentAttachment(urls: [URL]) {
        Task {
            await withTaskGroup(of: Void.self) { group in
                for url in urls {
                    group.addTask {
                        do {
                            let typeIdentifier = try url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier ?? ""

                            _ = try await self.sendAttachment(
                                url: url,
                                typeIdentifier: typeIdentifier,
                                name: url.lastPathComponent,
                                disposition: .attachment
                            )

                        } catch {
                            print("Error while creating attachment: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }

    func addImageAttachment(
        results: [PHPickerResult],
        disposition: AttachmentDisposition = .attachment,
        completion: @escaping (String) -> Void = { _ in
            // TODO: - Manage inline attachment
        }
    ) {
        Task {
            let itemProviders = results.map(\.itemProvider)
            await withTaskGroup(of: Void.self) { group in
                for itemProvider in itemProviders {
                    group.addTask {
                        do {
                            let typeIdentifier = itemProvider.registeredTypeIdentifiers.first ?? ""
                            let url = try await self.loadFileRepresentation(itemProvider, typeIdentifier: typeIdentifier)
                            let name = itemProvider.suggestedName ?? self.getDefaultFileName()

                            let attachment = try await self.sendAttachment(
                                url: url,
                                typeIdentifier: typeIdentifier,
                                name: name,
                                disposition: disposition
                            )
                            if disposition == .inline, let cid = attachment?.contentId {
                                completion(cid)
                            }
                        } catch {
                            print("Error while creating attachment: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }

    func addCameraAttachment(
        data: Data,
        disposition: AttachmentDisposition = .attachment,
        completion: @escaping (String) -> Void = { _ in
            // TODO: - Manage inline attachment
        }
    ) {
        Task {
            do {
                let typeIdentifier = "public.jpeg"
                let name = getDefaultFileName()

                let attachment = try await sendAttachment(
                    from: data,
                    typeIdentifier: typeIdentifier,
                    name: name,
                    disposition: disposition
                )

                if disposition == .inline, let cid = attachment?.contentId {
                    completion(cid)
                }
            } catch {
                print("Error while creating attachment: \(error.localizedDescription)")
            }
        }
    }

    func loadFileRepresentation(_ itemProvider: NSItemProvider, typeIdentifier: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
                if let url = url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: error ?? MailError.unknownError)
                }
            }
        }
    }

    private nonisolated func getDefaultFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmssSS"
        return formatter.string(from: Date())
    }

    private func sendAttachment(
        url: URL,
        typeIdentifier: String,
        name: String,
        disposition: AttachmentDisposition
    ) async throws -> Attachment? {
        let data = try Data(contentsOf: url)

        return try await sendAttachment(from: data, typeIdentifier: typeIdentifier, name: name, disposition: disposition)
    }

    private func sendAttachment(
        from data: Data,
        typeIdentifier: String,
        name: String,
        disposition: AttachmentDisposition
    ) async throws -> Attachment? {
        let uti = UTType(typeIdentifier)
        var name = name
        if let nameExtension = uti?.preferredFilenameExtension, !name.capitalized.hasSuffix(nameExtension.capitalized) {
            name.append(".\(nameExtension)")
        }

        let attachment = try await mailboxManager.apiFetcher.createAttachment(
            mailbox: mailboxManager.mailbox,
            attachmentData: data,
            disposition: disposition,
            attachmentName: name,
            mimeType: uti?.preferredMIMEType ?? "application/octet-stream"
        )
        await addAttachment(attachment)
        return attachment
    }
}
