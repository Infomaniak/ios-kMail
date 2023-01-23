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
                    Text(body.value)
                        .textStyle(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                } else {
                    GeometryReader { proxy in
                        WebView(model: $model, dynamicHeight: $webViewHeight, proxy: proxy)
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
                ShimmerView()
            }
        }
    }
}

struct MessageBodyView_Previews: PreviewProvider {
    static var previews: some View {
        MessageBodyView(message: PreviewHelper.sampleMessage)
    }
}
