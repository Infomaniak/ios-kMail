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

import Foundation
import MailCore
import OSLog
import UIKit

struct BodyImageProcessor {
    private let bodyImageMutator = BodyImageMutator()

    /// Download and encode all images for the current chunk in parallel.
    func fetchBase64Images(
        _ attachments: ArraySlice<Attachment>,
        mailboxManager: MailboxManager
    ) async -> [ImageBase64AndMime?] {
        // Force a fixed max concurrency to be a nice citizen to the network.
        let base64Images: [ImageBase64AndMime?] = await attachments
            .concurrentMap(customConcurrency: Constants.concurrentNetworkCalls) { attachment in
                do {
                    let attachmentData = try await mailboxManager.attachmentData(attachment, progressObserver: nil)

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
                    Logger.general.error("Error \(error) : Failed to fetch data  for attachment: \(attachment)")
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

        // On iOS17 Safari and iOS has support for heic. Quality is unchanged. Size is halved.
        let image = UIImage(data: attachmentData)
        guard let imageCompressed = image?.heicData(), imageCompressed.count < attachmentData.count else {
            let base64String = attachmentData.base64EncodedString()
            return ImageBase64AndMime(base64String, attachmentMime)
        }

        let base64String = imageCompressed.base64EncodedString()
        return ImageBase64AndMime(base64String, "image/heic")
    }

    /// Inject base64 images in a body
    func injectImagesInBody(
        body: String?,
        attachments: ArraySlice<Attachment>,
        base64Images: [ImageBase64AndMime?]
    ) async -> String? {
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
