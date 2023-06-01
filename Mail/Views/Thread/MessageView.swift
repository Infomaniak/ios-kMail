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

/// Something that can display an email
struct MessageView: View {
    @ObservedRealmObject var message: Message
    @State var presentableBody: PresentableBody
    @EnvironmentObject var mailboxManager: MailboxManager
    @State var isHeaderExpanded = false
    @State var isMessageExpanded: Bool

    /// True once we finished preprocessing the content
    @State var isMessagePreprocessed = false

    /// The cancellable task used to preprocess the content
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
            .onAppear {
                if message.fullyDownloaded,
                   isMessageExpanded,
                   !isMessagePreprocessed,
                   preprocessing == nil {
                    prepareBodyIfNeeded()
                }
            }
            .onDisappear {
                cancelPrepareBodyIfNeeded()
            }
        }
    }

    @MainActor private func fetchMessage() async {
        await tryOrDisplayError {
            try await mailboxManager.message(message: message)
        }
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
