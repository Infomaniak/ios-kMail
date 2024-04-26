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

import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftModalPresentation
import SwiftUI
import SwiftUIIntrospect

struct AIPromptView: View {
    @LazyInjectService var matomo: MatomoUtils

    @Environment(\.dismiss) private var dismiss
    @Environment(\.isCompactWindow) private var isCompactWindow

    // The focus is done thanks to UIKit, this allows the keyboard to appear more quickly
    @State private var hasFocusedEditor = false
    @State private var prompt = ""
    @ModalState(context: ContextKeys.aiAlert) private var isShowingAIEngineChoice = false
    @State private var placeholderProposition = Constants.aiPromptExamples.randomElement() ?? MailResourcesStrings.Localizable
        .aiPromptExample1

    @ObservedObject var aiModel: AIModel

    private var placeholder: String {
        if aiModel.isReplying {
            return MailResourcesStrings.Localizable.aiPromptAnswer
        } else {
            return MailResourcesStrings.Localizable.aiPromptPlaceholder(placeholderProposition)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIPadding.regular) {
            HStack(spacing: UIPadding.regular) {
                AIHeaderView(style: .bottomSheet)
                    .frame(maxWidth: .infinity, alignment: .leading)

                CloseButton(size: .regular, dismissAction: dismiss)
                    .tint(MailResourcesAsset.textSecondaryColor)
            }

            ZStack(alignment: .topLeading) {
                if prompt.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(Color(UIColor.placeholderText))
                        .textStyle(.body)
                        .padding([.vertical, .horizontal], value: .small)
                        .padding(.horizontal, 5)
                }

                TextEditor(text: $prompt)
                    .textStyle(.body)
                    .introspect(.textEditor, on: .iOS(.v15, .v16, .v17)) { textView in
                        if !hasFocusedEditor {
                            textView.becomeFirstResponder()
                            hasFocusedEditor = true
                        }
                        textView.backgroundColor = .clear
                        textView.textContainerInset = UIPadding.aiTextEditor
                        textView.font = .systemFont(ofSize: 16)
                    }
                    .frame(maxHeight: isCompactWindow ? nil : 128)
                    .tint(MailResourcesAsset.aiColor.swiftUIColor)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(MailResourcesAsset.textFieldBorder.swiftUIColor, lineWidth: 1)
            }

            HStack {
                AIEngineOptionButton(isShowingAIEngineChoice: $isShowingAIEngineChoice)

                Spacer()

                Button(MailResourcesStrings.Localizable.aiPromptValidateButton) {
                    matomo.track(eventWithCategory: .aiWriter, name: "generate")
                    aiModel.addInitialPrompt(prompt)
                    dismiss()
                }
                .buttonStyle(.ikPlain)
                .ikButtonPrimaryStyle(MailResourcesAsset.aiColor.swiftUIColor)
                .ikButtonSecondaryStyle(MailResourcesAsset.backgroundSecondaryColor.swiftUIColor)
                .disabled(prompt.isEmpty)
            }
        }
        .padding(isCompactWindow ? UIPadding.regular : 0)
        .onAppear {
            if aiModel.keepConversationWhenPropositionIsDismissed,
               let initialMessage = aiModel.conversation.first(where: { $0.type == .user }) {
                prompt = initialMessage.content
            }

            aiModel.resetConversation()
        }
        .onDisappear {
            if aiModel.isLoading {
                aiModel.isShowingProposition = true
            } else {
                matomo.track(eventWithCategory: .aiWriter, name: "dismissPromptWithoutGenerating")
            }
        }
        .sheet(isPresented: $isShowingAIEngineChoice) {
            PromptAIEngineOptionView()
        }
        .matomoView(view: ["AI", "Prompt"])
    }
}

#Preview {
    AIPromptView(aiModel: AIModel(
        mailboxManager: PreviewHelper.sampleMailboxManager,
        draftContentManager: PreviewHelper.sampleDraftContentManager,
        draft: Draft(),
        isReplying: false
    ))
}
