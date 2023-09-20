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
import SwiftUIIntrospect

struct AIPropositionView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var textPlainHeight = CGFloat.zero

    @Binding var aiResponse: AIResponse?

    var body: some View {
        NavigationView {
            ScrollView {
                SelectableTextView(textPlainHeight: $textPlainHeight, text: aiResponse?.content)
                    .frame(height: textPlainHeight)
                    .padding(.horizontal, value: .regular)
                    .tint(MailResourcesAsset.aiColor.swiftUIColor)
            }
            .matomoView(view: ["AI", "Prompt"])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(MailResourcesAsset.textSecondaryColor)
                    }
                }

                ToolbarItem(placement: .principal) {
                    AIHeaderView(style: .sheet)
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    AIPropositionMenu()

                    Spacer()

                    MailButton(icon: MailResourcesAsset.plus, label: MailResourcesStrings.Localizable.aiButtonInsert) {
                        // TODO: Insert data
                    }
                    .mailButtonCustomBackground(MailResourcesAsset.aiColor.swiftUIColor)
                }
            }
            .introspect(.viewController, on: .iOS(.v15, .v16, .v17)) { viewController in
                guard let toolbar = viewController.navigationController?.toolbar else { return }
                UIConstants.applyComposeViewStyle(to: toolbar)
            }
        }
    }
}

struct AIPropositionView_Previews: PreviewProvider {
    static var previews: some View {
        AIPropositionView(aiResponse: .constant(nil))
    }
}
