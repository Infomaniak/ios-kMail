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
    private let bodyImageMutator = BodyImageMutator()

    /// The presentableBody with the current pre-processing (partial or done)
    @Published var presentableBody: PresentableBody

    /// Set to true when done processing
    @Published var isMessagePreprocessed: Bool

    var mailboxManager: MailboxManager?

    private let messageUid: String

    /// Tracking the preprocessing Task tree
    private var processing: Task<Void, Error>?

    public init(messageUid: String) {
        self.messageUid = messageUid
        isMessagePreprocessed = false
        presentableBody = PresentableBody()
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

        let uuid = UUID().uuidString
        let messageUid = messageUid
        processing = Task { [weak self] in
            guard let message = mailboxManager.transactionExecutor.fetchObject(ofType: Message.self, forPrimaryKey: messageUid)?
                .freeze() else {
                return
            }

            await self?.prepareBody(frozenMessage: message)

            guard !Task.isCancelled else {
                return
            }

            await self?.insertInlineAttachments(frozenMessage: message)

            guard !Task.isCancelled else {
                return
            }

            await self?.processingCompleted()
        }
    }

    private func prepareBody(frozenMessage: Message) async {
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

    private func insertInlineAttachments(frozenMessage: Message) async {
        guard !Task.isCancelled else {
            return
        }

        // Since mutation of the DOM is costly, I batch the processing of images, then mutate the DOM.
        let attachmentsArray = frozenMessage.attachments.filter { $0.contentId != nil }.toArray()

        guard !attachmentsArray.isEmpty else {
            return
        }

        // Chunking, and processing each chunk. Opportunity to yield between each batch.
        let chunks = attachmentsArray.chunks(ofCount: Constants.inlineAttachmentBatchSize)
        for attachments in chunks {
            guard !Task.isCancelled else {
                return
            }

            // Run each batch in a `Task` to get an `autoreleasepool` behaviour
            let batchTask = Task {
                await processInlineAttachments(attachments)
            }
            await batchTask.finish()
            await Task.yield()
        }
    }

    private func processInlineAttachments(_ attachments: ArraySlice<Attachment>) async {
        guard !Task.isCancelled else {
            return
        }

        guard let mailboxManager else {
            DDLogError("processInlineAttachments will fail without a mailboxManager")
            return
        }

        // Download and encode all images for the current chunk in parallel.
        // Force a fixed max concurrency to be a nice citizen to the network.
        let base64Images: [String?] = await attachments
            .concurrentMap(customConcurrency: Constants.concurrentNetworkCalls) { attachment in
                do {
                    let attachmentData = try await mailboxManager.attachmentData(attachment)
                    let base64String = attachmentData.base64EncodedString()
                    return base64String
                } catch {
                    DDLogError("Error \(error) : Failed to fetch data  for attachment: \(attachment)")
                    return nil
                }
            }

        assert(base64Images.count == attachments.count, "Arrays count should match")

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
                  let base64Image = base64Images[safe: index] as? String else {
                continue
            }

            bodyImageMutator.replaceContentIdForBase64Image(
                in: &mailBody,
                contentId: contentId,
                mimeType: attachment.mimeType,
                contentBase64Encoded: base64Image
            )

            bodyImageMutator.replaceContentIdForBase64Image(
                in: &compactBody,
                contentId: contentId,
                mimeType: attachment.mimeType,
                contentBase64Encoded: base64Image
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

        // Mutate DOM if task is still active
        guard !Task.isCancelled else {
            return
        }
        await setPresentableBody(updatedPresentableBody)
    }

    @MainActor private func setPresentableBody(_ body: PresentableBody) {
        presentableBody = body
    }

    @MainActor func processingCompleted() {
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

/// Something to insert base64 image into a mail body. Easily testable.
struct BodyImageMutator {
    func replaceContentIdForBase64Image(
        in body: inout String?,
        contentId: String,
        mimeType: String,
        contentBase64Encoded: String
    ) {
        body = body?.replacingOccurrences(
            of: "cid:\(contentId)",
            with: "data:\(mimeType);base64,\(contentBase64Encoded)"
        )
    }
}
