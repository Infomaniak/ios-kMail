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

    @EnvironmentObject private var draftContentManager: DraftContentManager

    @State private var textPlainHeight = CGFloat.zero
    @State private var isShowingReplaceContentAlert = false
    @State private var contextId: String?
    @State private var isLoading = true

    @ObservedObject var aiModel: AIModel

    let mailboxManager: MailboxManager

    var body: some View {
        NavigationView {
            ScrollView {
                SelectableTextView(
                    textPlainHeight: $textPlainHeight,
                    text: aiModel.conversation.last?.content ?? "",
                    foregroundColor: isLoading ? MailResourcesAsset.textTertiaryColor.swiftUIColor : MailResourcesAsset
                        .textPrimaryColor.swiftUIColor
                )
                .frame(height: textPlainHeight)
                .padding(.horizontal, value: .regular)
                .tint(MailResourcesAsset.aiColor.swiftUIColor)
            }
            .task {
                do {
                    let result = try await mailboxManager.apiFetcher.createAIConversation(messages: aiModel.conversation)

                    withAnimation {
                        isLoading = false
                        aiModel.conversation.append(AIMessage(type: .assistant, content: result.content))
                        contextId = result.contextId
                    }
                } catch {
                    // TODO: Handle error (next PR)
                }
            }
            .onDisappear {
                aiModel.conversation = []
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(dismissAction: dismiss)
                        .tint(MailResourcesAsset.textSecondaryColor)
                }

                ToolbarItem(placement: .principal) {
                    AIHeaderView(style: .sheet)
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    AIPropositionMenu()
                        .opacity(isLoading ? 0 : 1)

                    Spacer()

                    ZStack(alignment: .trailing) {
                        AIProgressView()
                            .opacity(isLoading ? 1 : 0)
                        MailButton(icon: MailResourcesAsset.plus, label: MailResourcesStrings.Localizable.aiButtonInsert) {
                            guard !draftContentManager.hasContent else {
                                isShowingReplaceContentAlert = true
                                return
                            }
                            insertResult()
                        }
                        .opacity(isLoading ? 0 : 1)
                    }
                }
            }
            .introspect(.viewController, on: .iOS(.v15, .v16, .v17)) { viewController in
                guard let toolbar = viewController.navigationController?.toolbar else { return }
                UIConstants.applyComposeViewStyle(to: toolbar)
            }
            .customAlert(isPresented: $isShowingReplaceContentAlert) {
                ReplaceMessageContentView(action: insertResult)
            }
            .mailButtonPrimaryColor(MailResourcesAsset.aiColor.swiftUIColor)
            .mailButtonSecondaryColor(MailResourcesAsset.onAIColor.swiftUIColor)
            .tint(MailResourcesAsset.aiColor.swiftUIColor)
            .matomoView(view: ["AI", "Proposition"])
        }
    }

    private func insertResult() {
        guard !isLoading, let content = aiModel.conversation.last?.content else { return }
        draftContentManager.replaceBodyContent(with: content)
        dismiss()
    }
}

struct AIPropositionView_Previews: PreviewProvider {
    static var previews: some View {
        AIPropositionView(aiModel: AIModel(), mailboxManager: PreviewHelper.sampleMailboxManager)
    }
}
