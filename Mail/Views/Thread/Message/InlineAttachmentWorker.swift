/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

import Algorithms
import CocoaLumberjackSwift
import Foundation
import InfomaniakConcurrency
import InfomaniakCore
import MailCore
import SwiftUI

/// Something to process the Attachments outside of the mainActor
///
/// Call `start()` to begin processing, call `stop` to make sure internal Task is cancelled.
final class InlineAttachmentWorker: ObservableObject {
    /// Something to base64 encode images
    private let base64Encoder = Base64Encoder()

    /// The presentableBody with the current pre-processing (partial or done)
    @Published var presentableBody: PresentableBody

    /// Set to true when done processing
    var isMessagePreprocessed: Bool

    var mailboxManager: MailboxManager?

    let frozenMessage: Message

    /// Tracking the preprocessing Task tree
    private var processing: Task<Void, Error>?

    public init(frozenMessage: Message) {
        // TODO: assert frozen
        self.frozenMessage = frozenMessage
        isMessagePreprocessed = false
        presentableBody = PresentableBody(message: frozenMessage)
    }

    deinit {
        self.stop()
    }

    func stop() {
        processing?.cancel()
        processing = nil
    }

    func start(mailboxManager: MailboxManager) {
        // Content was processed or is processing
        guard !isMessagePreprocessed else {
            return
        }

        self.mailboxManager = mailboxManager

        processing = Task { [weak self] in
            await self?.prepareBody()

            guard !Task.isCancelled else {
                return
            }

            await self?.insertInlineAttachments()

            guard !Task.isCancelled else {
                return
            }

            await self?.processingCompleted()
        }
    }

    func prepareBody() async {
        guard !Task.isCancelled else {
            return
        }
        guard let updatedPresentableBody = await MessageBodyUtils.prepareWithPrintOption(message: frozenMessage) else { return }

        // Mutate DOM if task is active
        guard !Task.isCancelled else {
            return
        }
        await setPresentableBody(updatedPresentableBody)
    }

    func insertInlineAttachments() async {
        guard !Task.isCancelled else {
            return
        }

        // Since mutation of the DOM is costly, I batch the processing of images, then mutate the DOM.
        let attachmentsArray = frozenMessage.attachments.filter { $0.contentId != nil }.toArray()

        // Early exit, nothing to process
        guard !attachmentsArray.isEmpty else {
            return
        }

        // Chunking, and processing each chunk
        let chunks = attachmentsArray.chunks(ofCount: Constants.inlineAttachmentBatchSize)
        for attachments in chunks {
            guard !Task.isCancelled else {
                return
            }
            await processInlineAttachments(attachments)
        }
    }

    func processInlineAttachments(_ attachments: ArraySlice<Attachment>) async {
        guard !Task.isCancelled else {
            return
        }

        guard let mailboxManager = mailboxManager else {
            DDLogError("processInlineAttachments will fail without a mailboxManager")
            return
        }

        // Download all images for the current chunk in parallel
        let dataArray: [Data?] = await attachments.concurrentMap(customConcurrency: 4) { attachment in
            do {
                return try await mailboxManager.attachmentData(attachment)
            } catch {
                DDLogError("Error \(error) : Failed to fetch data  for attachment: \(attachment)")
                return nil
            }
        }

        // Safety check
        assert(dataArray.count == attachments.count, "Arrays count should match")

        guard !Task.isCancelled else {
            return
        }

        // Read the DOM once
        let bodyParameters = await readPresentableBody()
        var mailBody = bodyParameters.bodyString
        var compactBody = bodyParameters.compactBody
        let detachedBody = bodyParameters.detachedBody

        // Prepare the new DOM with the loaded images
        for (index, attachment) in attachments.enumerated() {
            guard !Task.isCancelled else {
                break
            }

            guard let contentId = attachment.contentId,
                  let data = dataArray[safe: index] as? Data else {
                continue
            }

            base64Encoder.replaceContentIdForBase64Image(
                in: &mailBody,
                contentId: contentId,
                mimeType: attachment.mimeType,
                contentData: data
            )

            base64Encoder.replaceContentIdForBase64Image(
                in: &compactBody,
                contentId: contentId,
                mimeType: attachment.mimeType,
                contentData: data
            )
        }

        let bodyValue = mailBody
        let compactBodyCopy = compactBody
        detachedBody?.value = bodyValue

        let updatedPresentableBody = PresentableBody(
            body: detachedBody,
            compactBody: compactBodyCopy,
            quotes: presentableBody.quotes
        )

        // Mutate DOM if task is active
        guard !Task.isCancelled else {
            return
        }
        await setPresentableBody(updatedPresentableBody)

        // Delay between each chunk processing, just enough, so the user feels the UI is responsive.
        // This goes beyond a simple Task.yield()
        try? await Task.sleep(nanoseconds: MessageView.batchCooldown)
    }

    @MainActor private func setPresentableBody(_ body: PresentableBody) {
        print("done processing body :\(frozenMessage.uid)")
        presentableBody = body
    }

    @MainActor func processingCompleted() {
        print("done processing all :\(frozenMessage.uid)")
        isMessagePreprocessed = true
    }

    typealias BodyParts = (bodyString: String?, compactBody: String?, detachedBody: Body?)
    @MainActor private func readPresentableBody() -> BodyParts {
        let mailBody = presentableBody.body?.value
        let compactBody = presentableBody.compactBody
        let detachedBody = presentableBody.body?.detached()

        return (mailBody, compactBody, detachedBody)
    }
}

struct Base64Encoder {
    func replaceContentIdForBase64Image(in body: inout String?, contentId: String, mimeType: String, contentData: Data) {
        body = body?.replacingOccurrences(
            of: "cid:\(contentId)",
            with: "data:\(mimeType);base64,\(contentData.base64EncodedString())"
        )
    }
}
