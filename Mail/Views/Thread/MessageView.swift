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

import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import RealmSwift
import Shimmer
import SwiftUI

struct MessageView: View {
    @ObservedRealmObject var message: Message
    @State var presentableBody: PresentableBody
    @EnvironmentObject var mailboxManager: MailboxManager
    @State var isHeaderExpanded = false
    @State var isMessageExpanded: Bool

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
                } else {
                    prepareBody()
                    await tryOrDisplayError {
                        try await insertInlineAttachments()
                    }
                }
            }
            .onChange(of: message.fullyDownloaded) { _ in
                if message.fullyDownloaded {
                    Task {
                        prepareBody()
                        await tryOrDisplayError {
                            try await insertInlineAttachments()
                        }
                    }
                }
            }
        }
    }

    @MainActor private func fetchMessage() async {
        await tryOrDisplayError {
            try await mailboxManager.message(message: message)
        }
    }

    private func prepareBody() {
        guard let messageBody = message.body else { return }
        presentableBody.body = messageBody.detached()

        guard let messageBodyQuote = MessageBodyUtils.splitBodyAndQuote(messageBody: messageBody.value ?? "")
        else { return }
        presentableBody.compactBody = messageBodyQuote.messageBody
        presentableBody.quote = messageBodyQuote.quote
    }

    private func insertInlineAttachments() {
        Task.detached() {
            // Since mutation of the DOM is costly, I batch the processing of images, then mutate the DOM.
            let attachmentsArray = await message.attachments.filter { $0.disposition == .inline }.toArray()
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
                await self.mutate(body: mailBody, compactBody: compactBody)

                // Delay between each chunk processing just enough, so the user feels the UI is responsive.
                try await Task.sleep(nanoseconds: 4_000_000_000)
            }
        }
    }

    /// Update the DOM in the main thread
    @MainActor func mutate(body: String?, compactBody: String?) {
        presentableBody.body?.value = body
        presentableBody.compactBody = compactBody
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
