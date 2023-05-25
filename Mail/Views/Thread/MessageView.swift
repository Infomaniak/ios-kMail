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
        let bodyValue = messageBody.value ?? ""

        // Heuristic to give up on mail too large for "perfect" preprocessing.
        // 5 Meg looks like a fine threshold
        guard bodyValue.lengthOfBytes(using: String.Encoding.utf8) < 5_000_000 else {
            DDLogInfo("give up on processing, file too large")
            mutate(compactBody: bodyValue, quote: nil)
            return
        }

        Task.detached {
            guard let messageBodyQuote = MessageBodyUtils.splitBodyAndQuote(messageBody: bodyValue) else {
                return
            }

            await mutate(compactBody: messageBodyQuote.messageBody, quote: messageBodyQuote.quote)
        }
    }

    /// Update the DOM in the main thread
    @MainActor func mutate(compactBody: String?, quote: String?) {
        presentableBody.compactBody = compactBody
        presentableBody.quote = quote
    }

    private func insertInlineAttachments() async throws {
        let attachmentsArray = message.attachments.filter { $0.disposition == .inline }.toArray()
        for attachment in attachmentsArray {
            if let contentId = attachment.contentId {
                let attachmentData = try await mailboxManager.attachmentData(attachment: attachment)

                presentableBody.body?.value = presentableBody.body?.value?.replacingOccurrences(
                    of: "cid:\(contentId)",
                    with: "data:\(attachment.mimeType);base64,\(attachmentData.base64EncodedString())"
                )
                presentableBody.compactBody = presentableBody.compactBody?.replacingOccurrences(
                    of: "cid:\(contentId)",
                    with: "data:\(attachment.mimeType);base64,\(attachmentData.base64EncodedString())"
                )
            }
        }
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
