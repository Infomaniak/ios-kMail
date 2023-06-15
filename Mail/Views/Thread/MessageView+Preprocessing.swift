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

import CocoaLumberjackSwift
import Foundation
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

        // Heuristic to give up on mail too large for "perfect" preprocessing.
        guard bodyValue.lengthOfBytes(using: String.Encoding.utf8) < Self.bodySizeThreshold else {
            DDLogInfo("give up on processing, file too large")
            mutate(compactBody: bodyValue, quote: nil)
            return
        }

        let task = Task.detached {
            guard let messageBodyQuote = MessageBodyUtils.splitBodyAndQuote(messageBody: bodyValue) else {
                return
            }

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

            // No more than 4 parallel downloads at a time
            let downloadMapper = ParallelTaskMapper(concurrency: 4)

            // chunk processing
            let chunks = attachmentsArray.chunked(into: 10)

            for chunk in chunks {
                guard !Task.isCancelled else {
                    break
                }

                try await processInlineAttachmentsChunk(chunk, downloadMapper: downloadMapper)
            }
        }
        await task.finish()
    }

    private func processInlineAttachmentsChunk(_ chunk: [Attachment], downloadMapper: ParallelTaskMapper) async throws {
        let task = Task.detached {
            // Download all images for the current chunk in parallel
            let dataArray = try await downloadMapper.map(collection: chunk) { item in
                try await mailboxManager.attachmentData(attachment: item)
            }.compactMap { $0 }

            // Read the DOM once
            var mailBody = await presentableBody.body?.value
            var compactBody = await presentableBody.compactBody

            // Prepare the new DOM with the loaded images
            for (index, attachment) in chunk.enumerated() {
                guard !Task.isCancelled else {
                    break
                }

                guard let contentId = attachment.contentId,
                      let data = dataArray[safe: index] else {
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

            guard !Task.isCancelled else {
                return
            }

            // Mutate DOM
            await mutate(body: mailBody, compactBody: compactBody)

            // Delay between each chunk processing, just enough, so the user feels the UI is responsive.
            try await Task.sleep(nanoseconds: Self.batchCooldown)
        }
        await task.finish()
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
