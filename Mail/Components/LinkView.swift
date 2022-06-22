//
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
import MailResources
import SwiftUI

struct LinkView: View {
    @State var url: String = ""

    @ObservedObject var bottomSheet: NewMessageBottomSheet
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Rentrez l'url")
                .textStyle(.header3)
            TextField("url", text: $url)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .keyboardType(.URL)
                .onAppear {
                    isFocused = true
                }
            HStack {
                Spacer()
                Button {
                    guard var urlComponents = URLComponents(string: url) else {
                        IKSnackBar.showSnackBar(message: "Invalid URL")
                        return
                    }
                    if urlComponents.scheme == nil {
                        urlComponents.scheme = "http"
                    }
                    guard let url = urlComponents.url?.absoluteString else {
                        IKSnackBar.showSnackBar(message: "Invalid URL")
                        return
                    }
                    bottomSheet.actionHandler?(url)
                } label: {
                    Text("Valider")
                        .textStyle(.buttonPill)
                }
                .tint(MailResourcesAsset.mailPinkColor)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 50))
                .controlSize(.large)
                .disabled(url.isEmpty)
            }
        }
        .padding()
    }
}

struct LinkView_Previews: PreviewProvider {
    static var previews: some View {
        LinkView(url: "url", bottomSheet: NewMessageBottomSheet())
    }
}
