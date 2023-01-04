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

        static let faq = HelpAction(title: MailResourcesStrings.Localizable.helpFAQ, destination: URLConstants.faq.url)
        static let chatbot = HelpAction(title: MailResourcesStrings.Localizable.helpChatbot, destination: URLConstants.chatbot.url)
    }

    @Environment(\.openURL) var openURL

    private let actions: [HelpAction] = [.faq, .chatbot]

    var body: some View {
        List {
            Section {
                ForEach(actions, id: \.self) { action in
                    VStack(alignment: .leading, spacing: 0) {
                        Button {
                            openURL(action.destination)
                        } label: {
                            Text(action.title)
                                .textStyle(.body)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)

                        if action != actions.last {
                            IKDivider()
                                .padding(.horizontal, 8)
                        }
                    }
                }
                .listRowBackground(MailResourcesAsset.backgroundColor.swiftUiColor)
                .listRowSeparator(.hidden)
                .listRowInsets(.init())
            } header: {
                Text(MailResourcesStrings.Localizable.helpSubtitle)
                    .textStyle(.bodySmallSecondary)
            }
            .listSectionSeparator(.hidden)
        }
        .listStyle(.plain)
        .background(MailResourcesAsset.backgroundColor.swiftUiColor)
        .navigationBarTitle(MailResourcesStrings.Localizable.buttonHelp, displayMode: .inline)
    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
    }
}
