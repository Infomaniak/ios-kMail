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
import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct MessageBodyView: View {
    let taskQueue = TaskQueue()

    @State private var textPlainHeight = CGFloat.zero

    @StateObject private var model = WebViewModel()

    @Binding var isMessagePreprocessed: Bool
    @Binding var presentableBody: PresentableBody
    var blockRemoteContent: Bool
    @Binding var displayContentBlockedActionView: Bool

    let messageUid: String

    var body: some View {
        ZStack {
            VStack {
                if let body = presentableBody.body {
                    if body.type == "text/plain" {
                        SelectableTextView(textPlainHeight: $textPlainHeight, text: body.value)
                            .padding(.horizontal, 16)
                            .frame(height: textPlainHeight)
                            .onAppear {
                                withAnimation {
                                    model.contentLoading = false
                                }
                            }
                    } else {
                        WebView(model: model, messageUid: messageUid)
                            .frame(height: model.webViewHeight)
                            .onAppear {
                                loadBody(blockRemoteContent: blockRemoteContent)
                            }
                            .onChange(of: presentableBody) { _ in
                                loadBody(blockRemoteContent: blockRemoteContent)
                            }
                            .onChange(of: model.showBlockQuote) { _ in
                                loadBody(blockRemoteContent: blockRemoteContent)
                            }
                            .onChange(of: blockRemoteContent) { newValue in
                                loadBody(blockRemoteContent: newValue)
                            }

                        if presentableBody.quote != nil {
                            MailButton(label: model.showBlockQuote
                                ? MailResourcesStrings.Localizable.messageHideQuotedText
                                : MailResourcesStrings.Localizable.messageShowQuotedText) {
                                    model.showBlockQuote.toggle()
                                }
                                .mailButtonStyle(.smallLink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .opacity(model.contentLoading ? 0 : 1)

            if model.contentLoading {
                ShimmerView()
            }
        }
    }

    private func loadBody(blockRemoteContent: Bool) {
        Task.detached {
            try await taskQueue.enqueue {
                let loadResult = await model.loadHTMLString(
                    value: model.showBlockQuote ? presentableBody.body?.value : presentableBody.compactBody,
                    blockRemoteContent: blockRemoteContent
                )

                await MainActor.run {
                    displayContentBlockedActionView = (loadResult == .remoteContentBlocked)
                }
            }
        }
    }
}

struct MessageBodyView_Previews: PreviewProvider {
    static var previews: some View {
        MessageBodyView(
            isMessagePreprocessed: .constant(true),
            presentableBody: .constant(PreviewHelper.samplePresentableBody),
            blockRemoteContent: false,
            displayContentBlockedActionView: .constant(false),
            messageUid: "message_uid"
        )
    }
}
