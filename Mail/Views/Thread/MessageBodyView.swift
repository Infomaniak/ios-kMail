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

import MailCore
import MailResources
import RealmSwift
import SwiftSoup
import SwiftUI

struct MessageBodyView: View {
    @State private var textPlainHeight = CGFloat.zero

    @StateObject private var model = WebViewModel()

    let isMessagePreprocessed: Bool
    @Binding var presentableBody: PresentableBody
    var blockRemoteContent: Bool
    @Binding var displayContentBlockedActionView: Bool

    let messageUid: String

    var body: some View {
        ZStack {
            VStack {
                if presentableBody.body != nil {
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
                        Button(model.showBlockQuote
                            ? MailResourcesStrings.Localizable.messageHideQuotedText
                            : MailResourcesStrings.Localizable.messageShowQuotedText) {
                                model.showBlockQuote.toggle()
                            }
                            .ikLinkButton(isInlined: true)
                            .controlSize(.small)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, value: .regular)
                    }
                }
            }
            .opacity(model.initialContentLoading ? 0 : 1)

            if model.initialContentLoading {
                ShimmerView()
            }
        }
    }

    private func loadBody(blockRemoteContent: Bool) {
        Task {
            let loadResult = await model.loadBody(presentableBody: presentableBody, blockRemoteContent: blockRemoteContent)

            displayContentBlockedActionView = (loadResult == .remoteContentBlocked)
        }
    }
}

struct MessageBodyView_Previews: PreviewProvider {
    static var previews: some View {
        MessageBodyView(
            isMessagePreprocessed: true,
            presentableBody: .constant(PreviewHelper.samplePresentableBody),
            blockRemoteContent: false,
            displayContentBlockedActionView: .constant(false),
            messageUid: "message_uid"
        )
    }
}
