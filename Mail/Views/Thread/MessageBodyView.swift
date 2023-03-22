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
import SwiftUI

struct MessageBodyView: View {
    @ObservedRealmObject var message: Message
    @State var model = WebViewModel()
    @State private var webViewShortHeight: CGFloat = .zero
    @State private var webViewCompleteHeight: CGFloat = .zero

    @State private var bodyQuote = MessageBodyQuote(messageBody: "", quote: nil)
    @State private var showBlockQuote = false

    init(message: Message) {
        self.message = message
    }

    var body: some View {
        VStack {
            if let body = message.body {
                if body.type == "text/plain" {
                    Text(body.value ?? "")
                        .textStyle(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                } else {
                    GeometryReader { proxy in
                        WebView(
                            model: $model,
                            shortHeight: $webViewShortHeight,
                            completeHeight: $webViewCompleteHeight,
                            proxy: proxy
                        )
                    }
                    .frame(height: showBlockQuote ? webViewCompleteHeight : webViewShortHeight)
                    .onAppear {
                        prepareBody()
                        loadBody(body)
                    }
                    .onChange(of: message.body) { _ in
                        prepareBody()
                        loadBody(body)
                    }
                    .onChange(of: showBlockQuote) { _ in
                        loadBody(body)
                    }

                    if bodyQuote.quote != nil {
                        Button {
                            showBlockQuote.toggle()
                        } label: {
                            Text(showBlockQuote
                                ? MailResourcesStrings.Localizable.messageHideQuotedText
                                : MailResourcesStrings.Localizable.messageShowQuotedText)
                        }
                        .mailButtonStyle(.smallLink)
                    }
                }
            } else {
                // Display a shimmer while the body is loading
                ShimmerView()
            }
        }
    }

    private func prepareBody() {
        guard let messageBody = message.body?.value,
              let messageBodyQuote = MessageBodyUtils.splitBodyAndQuote(messageBody: messageBody)
        else { return }
        bodyQuote = messageBodyQuote
    }

    private func loadBody(_ body: Body) {
        model.loadHTMLString(value: showBlockQuote ? body.value : bodyQuote.messageBody)
    }
}

struct MessageBodyView_Previews: PreviewProvider {
    static var previews: some View {
        MessageBodyView(message: PreviewHelper.sampleMessage)
    }
}
