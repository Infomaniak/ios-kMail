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

import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct AIPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isCompactWindow) private var isCompactWindow

    @State private var userPrompt = ""

    @Binding var aiMessage: AIResponse?

    let mailboxManager: MailboxManager

    var body: some View {
        VStack(alignment: .leading, spacing: UIPadding.regular) {
            HStack(spacing: UIPadding.regular) {
                AIHeaderView()
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundColor(MailResourcesAsset.textSecondaryColor)
                }
            }

            ZStack(alignment: .topLeading) {
                if userPrompt.isEmpty {
                    Text(MailResourcesStrings.Localizable.aiPromptPlaceholder)
                        .foregroundColor(Color(UIColor.placeholderText))
                        .textStyle(.body)
                        .padding(.horizontal, 5)
                }

                TextEditor(text: $userPrompt)
                    .textStyle(.body)
                    .introspect(.textEditor, on: .iOS(.v15, .v16, .v17)) { textField in
                        textField.backgroundColor = .clear
                        textField.textContainerInset = .zero
                        textField.font = .systemFont(ofSize: 16)
                        textField.becomeFirstResponder()
                    }
                    .tint(MailResourcesAsset.aiColor.swiftUIColor)
                    .frame(maxHeight: isCompactWindow ? nil : 128)
            }
            .padding(value: .small)
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(MailResourcesAsset.textFieldBorder.swiftUIColor, lineWidth: 1)
            }

            MailButton(label: MailResourcesStrings.Localizable.aiPromptValidateButton) {
                Task {
                    let message = AIMessage(type: .user, content: userPrompt)
                    try await accountManager.currentApiFetcher?.createAIConversation(messages: [message])
                MailButton(label: MailResourcesStrings.Localizable.aiPromptValidateButton, action: askAI)
                    .mailButtonCustomTextStyle(.bodyMediumOnAI)
                    .mailButtonCustomBackground(MailResourcesAsset.aiColor.swiftUIColor)
                    .opacity(isLoading ? 0 : 1)
                }
            }
            .mailButtonCustomTextStyle(.bodyMediumOnAI)
            .mailButtonCustomBackground(MailResourcesAsset.aiColor.swiftUIColor)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(value: .regular)
    }

    private func askAI() {
        Task {
            isLoading = true
            let message = AIMessage(type: .user, content: userPrompt)
            let result = try await mailboxManager.apiFetcher.createAIConversation(messages: [message])
            isLoading = false

            dismissView()
            aiMessage = result
        }
    }

    private func dismissView() {
        userPrompt = ""
        dismiss()
    }
}

struct AIPromptView_Previews: PreviewProvider {
    static var previews: some View {
        AIPromptView(aiMessage: .constant(nil), mailboxManager: PreviewHelper.sampleMailboxManager)
    }
}
