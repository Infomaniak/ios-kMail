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
    @Binding var presentableBody: PresentableBody

    @State var model = WebViewModel()
    @State private var webViewShortHeight: CGFloat = .zero
    @State private var webViewCompleteHeight: CGFloat = .zero

    @State private var showBlockQuote = false

    var body: some View {
        VStack {
            if let body = presentableBody.body {
                if body.type == "text/plain" {
                    SelectableTextView(text: body.value)
                        .padding(.horizontal, 16)
                } else {
                    GeometryReader { proxy in
                        WebView(
                            model: $model,
                            shortHeight: $webViewShortHeight,
                            completeHeight: $webViewCompleteHeight,
                            withQuote: $showBlockQuote,
                            proxy: proxy
                        )
                    }
                    .frame(height: showBlockQuote ? webViewCompleteHeight : webViewShortHeight)
                    .onAppear {
                        loadBody()
                    }
                    .onChange(of: presentableBody) { _ in
                        loadBody()
                    }
                    .onChange(of: showBlockQuote) { _ in
                        loadBody()
                    }

                    if presentableBody.quote != nil {
                        MailButton(label: showBlockQuote
                            ? MailResourcesStrings.Localizable.messageHideQuotedText
                            : MailResourcesStrings.Localizable.messageShowQuotedText) {
                                showBlockQuote.toggle()
                            }
                            .mailButtonStyle(.smallLink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                    }
                }
            } else {
                // Display a shimmer while the body is loading
                ShimmerView()
            }
        }
    }

    private func loadBody() {
        model.loadHTMLString(value: showBlockQuote ? presentableBody.body?.value : presentableBody.compactBody)
    }
}

struct MessageBodyView_Previews: PreviewProvider {
    static var previews: some View {
        MessageBodyView(presentableBody: .constant(PreviewHelper.samplePresentableBody))
    }
}
