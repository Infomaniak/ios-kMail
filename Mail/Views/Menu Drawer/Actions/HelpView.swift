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
import SwiftUI

struct HelpView: View {
    private struct HelpAction: Hashable {
        let title: String
        let destination: URL

        static let faq = HelpAction(title: "FAQ", destination: URLConstants.faq.url)
        static let chatbot = HelpAction(title: "Chatbot", destination: URLConstants.chatbot.url)
    }

    @Environment(\.openURL) var openURL

    @Binding var isPresented: Bool

    private let actions: [HelpAction] = [.faq, .chatbot]

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Pour vous aider")
                    .textStyle(.calloutSecondary)

                ForEach(actions, id: \.self) { action in
                    Button(action.title) {
                        openURL(action.destination)
                    }
                    .textStyle(.body)

                    if action != actions.last {
                        IKDivider()
                    }
                }

                Spacer()
            }
            .padding(.top, 24)
            .padding(.horizontal, 18)
            .navigationBarTitle(MailResourcesStrings.Localizable.buttonHelp, displayMode: .inline)
            .navigationBarItems(leading: Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
            })
        }
        .navigationBarAppStyle()
    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView(isPresented: .constant(true))
    }
}
