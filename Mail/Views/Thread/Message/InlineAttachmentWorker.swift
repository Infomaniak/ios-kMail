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
    private let bodyImageProcessor = BodyImageProcessor()

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
        stop()
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

        let base64Images = await bodyImageProcessor.fetchBase64Images(attachments, mailboxManager: mailboxManager)

        guard !Task.isCancelled else {
            return
        }

        // Read the DOM once
        let bodyParameters = await readPresentableBody()
        let detachedBody = bodyParameters.detachedBody

        // process compact and base body in parallel
        async let mailBody = bodyImageProcessor.injectImagesInBody(body: bodyParameters.bodyString,
                                                                   attachments: attachments,
                                                                   base64Images: base64Images)

        async let compactBody = bodyImageProcessor.injectImagesInBody(body: bodyParameters.compactBody,
                                                                      attachments: attachments,
                                                                      base64Images: base64Images)

        let bodyValue = await mailBody
        let compactBodyCopy = await compactBody
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

/// Something to package a base64 encoded image and its mime type
typealias ImageBase64AndMime = (imageEncoded: String, mimeType: String)

/// Download compress and format images into a mail body
struct BodyImageProcessor {
    private let bodyImageMutator = BodyImageMutator()

    /// Download and encode all images for the current chunk in parallel.
    public func fetchBase64Images(_ attachments: ArraySlice<Attachment>,
                                  mailboxManager: MailboxManager) async -> [ImageBase64AndMime?] {
        // Force a fixed max concurrency to be a nice citizen to the network.
        let base64Images: [ImageBase64AndMime?] = await attachments
            .concurrentMap(customConcurrency: Constants.concurrentNetworkCalls) { attachment in
                do {
                    let attachmentData = try await mailboxManager.attachmentData(attachment)

                    // Skip compression on non static images types or already heic sources
                    guard attachment.mimeType.contains("jpg")
                        || attachment.mimeType.contains("jpeg")
                        || attachment.mimeType.contains("png") else {
                        let base64String = attachmentData.base64EncodedString()
                        return ImageBase64AndMime(base64String, attachment.mimeType)
                    }

                    // Skip compression with lockdown mode enables as images can glitch
                    let isLockdownModeEnabled = (UserDefaults.standard.object(forKey: "LDMGlobalEnabled") as? Bool) ?? false
                    guard !isLockdownModeEnabled else {
                        let base64String = attachmentData.base64EncodedString()
                        return ImageBase64AndMime(base64String, attachment.mimeType)
                    }

                    let compressedImage = compressedBase64ImageAndMime(
                        attachmentData: attachmentData,
                        attachmentMime: attachment.mimeType
                    )
                    return compressedImage

                } catch {
                    DDLogError("Error \(error) : Failed to fetch data  for attachment: \(attachment)")
                    return nil
                }
            }

        assert(base64Images.count == attachments.count, "Arrays count should match")
        return base64Images
    }

    /// Try to compress the attachment with the best matched algorithm. Trade CPU cycles to reduce render time and memory usage.
    private func compressedBase64ImageAndMime(attachmentData: Data, attachmentMime: String) -> ImageBase64AndMime {
        guard #available(iOS 17.0, *) else {
            let base64String = attachmentData.base64EncodedString()
            return ImageBase64AndMime(base64String, attachmentMime)
        }

        // On iOS17 Safari _and_ iOS has support for heic. Quality is unchanged. Size is halved.
        let image = UIImage(data: attachmentData)
        guard let imageCompressed = image?.heicData(),
              imageCompressed.count < attachmentData.count else {
            let base64String = attachmentData.base64EncodedString()
            return ImageBase64AndMime(base64String, attachmentMime)
        }

        let base64String = imageCompressed.base64EncodedString()
        return ImageBase64AndMime(base64String, "image/heic")
    }

    /// Inject base64 images in a body
    public func injectImagesInBody(body: String?,
                                   attachments: ArraySlice<Attachment>,
                                   base64Images: [ImageBase64AndMime?]) async -> String? {
        guard let body, !body.isEmpty else {
            return nil
        }

        var workingBody = body
        for (index, attachment) in attachments.enumerated() {
            guard !Task.isCancelled else {
                break
            }

            guard let contentId = attachment.contentId,
                  let base64Image = base64Images[safe: index] as? ImageBase64AndMime else {
                continue
            }

            bodyImageMutator.replaceContentIdForBase64Image(
                in: &workingBody,
                contentId: contentId,
                mimeType: base64Image.mimeType,
                contentBase64Encoded: base64Image.imageEncoded
            )
        }
        return workingBody
    }
}

/// Something to insert base64 image into a mail body. Easily testable.
struct BodyImageMutator {
    func replaceContentIdForBase64Image(
        in body: inout String,
        contentId: String,
        mimeType: String,
        contentBase64Encoded: String
    ) {
        body = body.replacingOccurrences(
            of: "cid:\(contentId)",
            with: "data:\(mimeType);base64,\(contentBase64Encoded)"
        )
    }
}
