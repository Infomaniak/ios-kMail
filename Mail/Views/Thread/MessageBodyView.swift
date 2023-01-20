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
import RealmSwift
import SwiftUI

struct MessageBodyView: View {
    @ObservedRealmObject var message: Message
    @State var model = WebViewModel()
    @State private var webViewHeight: CGFloat = .zero

    var body: some View {
        VStack {
            if let body = message.body {
                if body.type == "text/plain" {
                    Text(message.body?.value ?? "")
                        .textStyle(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                } else {
                    GeometryReader { proxy in
                        WebView(model: $model, dynamicHeight: $webViewHeight, proxy: proxy)
                            .frame(height: webViewHeight)
                    }
                    .frame(height: webViewHeight)
                    .onAppear {
                        model.loadHTMLString(value: body.value)
                    }
                    .onChange(of: message.body) { _ in
                        model.loadHTMLString(value: body.value)
                    }
                }
            } else {
                // Display a shimmer while the body is loading
                Text(
                    "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras elementum justo quis neque iaculis, eget vehicula metus vulputate. Duis sit amet tempor nisl. Nulla ac semper risus, nec rutrum elit. Maecenas sed volutpat urna. Vestibulum varius ac orci eu eleifend. Sed at ullamcorper odio. Donec sodales, nisl vel pellentesque scelerisque, ligula justo efficitur ex, non vestibulum nisi purus sit amet dui. Praesent ultricies orci et enim hendrerit posuere eget quis leo. Mauris sit amet sollicitudin mi. Suspendisse volutpat odio ante, quis elementum massa congue sed. Sed varius varius tempus."
                )
                .redacted(reason: .placeholder)
                .shimmering()
                .padding(.horizontal, 16)
            }
        }
    }
}

struct MessageBodyView_Previews: PreviewProvider {
    static var previews: some View {
        MessageBodyView(message: PreviewHelper.sampleMessage)
    }
}
