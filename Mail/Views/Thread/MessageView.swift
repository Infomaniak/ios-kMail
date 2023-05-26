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
import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import RealmSwift
import Shimmer
import SwiftUI

// TODO: Move to core
extension Task {
    @discardableResult
    func finish() async -> Result<Success, Failure> {
        await result
    }
}

struct MessageView: View {
    @ObservedRealmObject var message: Message
    @State var presentableBody: PresentableBody
    @EnvironmentObject var mailboxManager: MailboxManager
    @State var isHeaderExpanded = false
    @State var isMessageExpanded: Bool
    @State var isMessagePreprocessed = false
    @State var preprocessing: Task<Void, Never>?

    @LazyInjectService var matomo: MatomoUtils

    init(message: Message, isMessageExpanded: Bool = false) {
        self.message = message
        presentableBody = PresentableBody(message: message)
        self.isMessageExpanded = isMessageExpanded
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                MessageHeaderView(
                    message: message,
                    isHeaderExpanded: $isHeaderExpanded,
                    isMessageExpanded: $isMessageExpanded
                )
                .padding(.horizontal, 16)

                if isMessageExpanded {
                    if !message.attachments.filter({ $0.disposition == .attachment || $0.contentId == nil }).isEmpty {
                        AttachmentsView(message: message)
                            .padding(.top, 24)
                    }
                    MessageBodyView(presentableBody: $presentableBody, messageUid: message.uid)
                        .padding(.top, 16)
                }
            }
            .padding(.vertical, 16)
            .task {
                if self.message.shouldComplete {
                    await fetchMessage()
                }
            }
            .onChange(of: message.fullyDownloaded) { _ in
                if message.fullyDownloaded, isMessageExpanded {
                    prepareBodyIfNeeded()
                }
            }
            .onChange(of: isMessageExpanded) { _ in
                if message.fullyDownloaded, isMessageExpanded {
                    prepareBodyIfNeeded()
                } else {
                    cancelPrepareBodyIfNeeded()
                }
            }
            .onAppear() {
                if message.fullyDownloaded,
                    isMessageExpanded,
                    !isMessagePreprocessed,
                    preprocessing == nil {
                    prepareBodyIfNeeded()
                }
            }
            .onDisappear() {
                cancelPrepareBodyIfNeeded()
            }
        }
    }

    @MainActor private func fetchMessage() async {
        await tryOrDisplayError {
            try await mailboxManager.message(message: message)
        }
    }

    private func prepareBodyIfNeeded() {
        print("aa prepareBodyIfNeeded")
        guard !isMessagePreprocessed else {
            return
        }

        preprocessing = Task.detached {
            guard !Task.isCancelled else { return }
            await prepareBody()
            guard !Task.isCancelled else { return }
            await insertInlineAttachments()
            guard !Task.isCancelled else { return }
            await processingCompleted()
        }
    }

    private func cancelPrepareBodyIfNeeded() {
        print("xx cancelPrepareBodyIfNeeded")
        guard let preprocessing else {
            return
        }
        preprocessing.cancel()
        print("xx did cancel PrepareBodyIfNeeded")
    }

    // TODO: split task in struct maybe ?
    private func prepareBody() async {
        print("••prepareBody")
        guard let messageBody = message.body else {
            return
        }

        presentableBody.body = messageBody.detached()
        let bodyValue = messageBody.value ?? ""

        // Heuristic to give up on mail too large for "perfect" preprocessing.
        // 1 Meg looks like a fine threshold
        guard bodyValue.lengthOfBytes(using: String.Encoding.utf8) < 1_000_000 else {
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
        print("••insertInlineAttachments")
        let task = Task.detached {
            // Since mutation of the DOM is costly, I batch the processing of images, then mutate the DOM.
            let attachmentsArray = await message.attachments.filter { $0.disposition == .inline }.toArray()

            // Early exit, nothing to process
            guard !attachmentsArray.isEmpty else {
                return
            }

            // chunk processing
            let chunks = attachmentsArray.chunked(into: 10)
            for chunk in chunks {
                // Download images for the current chunk
                let dataArray = try await chunk.asyncMap {
                    try await mailboxManager.attachmentData(attachment: $0)
                }

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

                    mailBody = mailBody?.replacingOccurrences(
                        of: "cid:\(contentId)",
                        with: "data:\(attachment.mimeType);base64,\(data.base64EncodedString())"
                    )
                    compactBody = compactBody?.replacingOccurrences(
                        of: "cid:\(contentId)",
                        with: "data:\(attachment.mimeType);base64,\(data.base64EncodedString())"
                    )
                }

                // Mutate DOM
                await mutate(body: mailBody, compactBody: compactBody)

                // Delay between each chunk processing just enough, so the user feels the UI is responsive.
                try await Task.sleep(nanoseconds: 4_000_000_000)
            }
        }
        await task.finish()
    }

    /// Update the DOM in the main actor
    @MainActor func mutate(compactBody: String?, quote: String?) {
        presentableBody.compactBody = compactBody
        presentableBody.quote = quote
    }

    /// Update the DOM in the main actor
    @MainActor func mutate(body: String?, compactBody: String?) {
        presentableBody.body?.value = body
        presentableBody.compactBody = compactBody
    }

    /// preprocess is finished
    @MainActor func processingCompleted() {
        print("••processingCompleted")
        isMessagePreprocessed = true
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MessageView(message: PreviewHelper.sampleMessage)

            MessageView(message: PreviewHelper.sampleMessage, isMessageExpanded: true)
        }
        .previewLayout(.sizeThatFits)
    }
}
