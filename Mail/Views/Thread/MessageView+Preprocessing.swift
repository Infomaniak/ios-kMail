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

import Algorithms
import CocoaLumberjackSwift
import Foundation
import InfomaniakConcurrency
import InfomaniakCore
import MailCore

/// MessageView code related to pre-processing
extension MessageView {
    /// Maximum body size supported for preprocessing
    ///
    /// 1 Meg looks like a fine threshold
    private static let bodySizeThreshold = 1_000_000

    /// Cooldown before processing each batch of inline images
    ///
    /// 4 seconds feels fine
    private static let batchCooldown: UInt64 = 4_000_000_000

    // MARK: - public interface

    func prepareBodyIfNeeded() {
        // Content was processed
        guard !isMessagePreprocessed else {
            return
        }

        // Clean task if existing
        cancelPrepareBodyIfNeeded()

        preprocessing = Task.detached {
            guard !Task.isCancelled else { return }
            await prepareBody()
            guard !Task.isCancelled else { return }
            await insertInlineAttachments()
            guard !Task.isCancelled else { return }
            await processingCompleted()
        }
    }

    func cancelPrepareBodyIfNeeded() {
        guard let preprocessing else {
            return
        }
        preprocessing.cancel()
        self.preprocessing = nil
    }

    // MARK: - private

    private func prepareBody() async {
        guard let messageBody = message.body else {
            return
        }

        let detachedMessage = messageBody.detached()
        presentableBody.body = detachedMessage
        let bodyValue = detachedMessage.value ?? ""

        let task = Task.detached {
            let messageBodyQuote = await MessageBodyUtils.splitBodyAndQuote(messageBody: bodyValue)
            await mutate(compactBody: messageBodyQuote.messageBody, quote: messageBodyQuote.quote)
        }

        await task.finish()
    }

    private func insertInlineAttachments() async {
        let task = Task.detached {
            // Since mutation of the DOM is costly, I batch the processing of images, then mutate the DOM.
            let attachmentsArray = await message.attachments.filter { $0.contentId != nil }.toArray()

            // Early exit, nothing to process
            guard !attachmentsArray.isEmpty else {
                return
            }

            // Chunking, and processing each chunk with a `concurrentForEach`
            let chunks = attachmentsArray.chunks(ofCount: 10)
            for attachments in chunks {
                try await attachments.concurrentForEach { attachment in
                    guard !Task.isCancelled else {
                        return
                    }

                    try await InlineAttachmentWorker.processInlineAttachment(attachment, messageView: self)
                }
            }
        }
        await task.finish()
    }

    /// Something to process the Attachments outside of the mainActor
    private enum InlineAttachmentWorker {
        static func processInlineAttachment(_ attachment: Attachment, messageView: MessageView) async throws {
            // Download all images for the current chunk in parallel
            let data = try await messageView.mailboxManager.attachmentData(attachment: attachment)

            guard !Task.isCancelled else {
                return
            }

            // Read the DOM once
            var mailBody = await messageView.presentableBody.body?.value
            var compactBody = await messageView.presentableBody.compactBody

            // Prepare the new DOM with the loaded images
            guard let contentId = attachment.contentId else {
                return
            }

            messageView.base64Encoder.replaceContentIdForBase64Image(
                in: &mailBody,
                contentId: contentId,
                mimeType: attachment.mimeType,
                contentData: data
            )

            messageView.base64Encoder.replaceContentIdForBase64Image(
                in: &compactBody,
                contentId: contentId,
                mimeType: attachment.mimeType,
                contentData: data
            )

            // Mutate DOM
            await messageView.mutate(body: mailBody, compactBody: compactBody)

            // Delay between each chunk processing, just enough, so the user feels the UI is responsive.
            // This goes beyond a simple Task.yield()
            try await Task.sleep(nanoseconds: MessageView.batchCooldown)
        }
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
