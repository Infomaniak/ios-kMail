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

import MailCore
import MailCoreUI
import MailResources
import SwiftUI

struct MessageBodyView: View {
    @EnvironmentObject private var messagesWorker: MessagesWorker
    @EnvironmentObject private var threadViewState: ThreadViewState

    @State private var isShowingLoadingError = false

    @Binding var displayContentBlockedActionView: Bool
    @Binding var initialContentLoading: Bool

    let isRemoteContentBlocked: Bool
    let isShowingTranslated: Bool
    let messageUid: String

    private var messageTheme: MessageTheme {
        if UserDefaults.shared.shouldShowDarkMode && !threadViewState.forcedLightModes.contains(messageUid) {
            .auto
        } else {
            .light
        }
    }

    private var translatedPresentableBody: PresentableBody? {
        messagesWorker.presentableBody(for: messageUid, isShowingTranslated: true)
    }

    private var isTranslationInProgress: Bool {
        guard case .showContent = threadViewState.translatedMessages[messageUid] else {
            return false
        }

        return translatedPresentableBody == nil
    }

    var body: some View {
        ZStack {
            if isTranslationInProgress {
                ShimmerView()
            } else if isShowingLoadingError {
                Text(MailResourcesStrings.Localizable.errorLoadingMessage)
                    .textStyle(.bodySmallItalicSecondary)
                    .padding(value: .medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                MessageBodyContentView(
                    displayContentBlockedActionView: $displayContentBlockedActionView,
                    initialContentLoading: $initialContentLoading,
                    presentableBody: messagesWorker.presentableBody(for: messageUid, isShowingTranslated: isShowingTranslated),
                    blockRemoteContent: isRemoteContentBlocked,
                    messageUid: messageUid,
                    messageTheme: messageTheme
                )
                .id(messageTheme.cssProperty)
            }
        }
        .task {
            await tryOrDisplayError {
                do {
                    try await messagesWorker.fetchAndProcessIfNeeded(messageUid: messageUid)
                } catch is MessagesWorker.WorkerError {
                    isShowingLoadingError = true
                }
            }
        }
    }
}

#Preview {
    MessageBodyView(
        displayContentBlockedActionView: .constant(false),
        initialContentLoading: .constant(false),
        isRemoteContentBlocked: false,
        isShowingTranslated: false,
        messageUid: PreviewHelper.sampleMessage.uid
    )
    .environmentObject(MessagesWorker(mailboxManager: PreviewHelper.sampleMailboxManager))
    .environmentObject(ThreadViewState())
}
