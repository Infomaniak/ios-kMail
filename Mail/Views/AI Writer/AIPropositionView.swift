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
import MailResources
import RealmSwift
import SwiftUI
import SwiftUIIntrospect

struct AIPropositionView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var draftContentManager: DraftContentManager

    @State private var textPlainHeight = CGFloat.zero
    @State private var isShowingReplaceContentAlert = false

    @ObservedObject var aiModel: AIModel

    @ObservedRealmObject var draft: Draft

    var body: some View {
        NavigationView {
            ScrollView {
                Group {
                    if let error = aiModel.error {
                        Text(error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        SelectableTextView(
                            textPlainHeight: $textPlainHeight,
                            text: aiModel.conversation.last?.content ?? "",
                            foregroundColor: aiModel.isLoading ? MailResourcesAsset.textTertiaryColor
                                .swiftUIColor : MailResourcesAsset
                                .textPrimaryColor.swiftUIColor
                        )
                        .frame(height: textPlainHeight)
                        .tint(MailResourcesAsset.aiColor.swiftUIColor)
                    }
                }
                .padding(.horizontal, value: .regular)
            }
            .onAppear {
                withAnimation {
                    aiModel.isLoading = true
                }
            }
            .task {
                await aiModel.createConversation()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton {
                        matomo.track(eventWithCategory: .aiWriter, name: "dismissProposition")
                        dismiss()
                    }
                    .tint(MailResourcesAsset.textSecondaryColor)
                }

                ToolbarItem(placement: .principal) {
                    AIHeaderView(style: .sheet)
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    Group {
                        if !aiModel.isLoading && aiModel.error == nil {
                            AIPropositionMenu(aiModel: aiModel)
                        }

                        Spacer()

                        if aiModel.isLoading {
                            AIProgressView()
                        } else if aiModel.error != nil {
                            MailButton(label: MailResourcesStrings.Localizable.aiButtonRetry) {
                                matomo.track(eventWithCategory: .aiWriter, name: "retry")
                                aiModel.displayView(.prompt)
                            }
                        } else {
                            MailButton(icon: MailResourcesAsset.plus, label: MailResourcesStrings.Localizable.aiButtonInsert) {
                                let shouldReplaceContent = !draft.isBodyEmpty
                                guard !shouldReplaceContent || shouldReplaceContent && UserDefaults.shared
                                    .doNotShowAIReplaceMessageAgain else {
                                    matomo.track(eventWithCategory: .aiWriter, name: "replacePropositionDialog")
                                    isShowingReplaceContentAlert = true
                                    return
                                }
                                insertResult(shouldReplaceContent)
                            }
                        }
                    }
                    .padding(.bottom, value: .verySmall)
                }
            }
            .introspect(.viewController, on: .iOS(.v15, .v16, .v17)) { viewController in
                guard let toolbar = viewController.navigationController?.toolbar else { return }
                UIConstants.applyComposeViewStyle(to: toolbar)
            }
            .customAlert(isPresented: $isShowingReplaceContentAlert) {
                ReplaceMessageContentView {
                    insertResult(true)
                }
            }
            .mailButtonPrimaryColor(MailResourcesAsset.aiColor.swiftUIColor)
            .mailButtonSecondaryColor(MailResourcesAsset.onAIColor.swiftUIColor)
            .tint(MailResourcesAsset.aiColor.swiftUIColor)
            .matomoView(view: ["AI", "Proposition"])
        }
    }

    private func insertResult(_ shouldReplaceContent: Bool) {
        guard !aiModel.isLoading, let content = aiModel.conversation.last?.content else { return }
        matomo.track(
            eventWithCategory: .aiWriter,
            action: .data,
            name: shouldReplaceContent ? "replaceProposition" : "insertProposition"
        )

        draftContentManager.replaceBodyContent(with: content)
        dismiss()
    }
}

struct AIPropositionView_Previews: PreviewProvider {
    static var previews: some View {
        AIPropositionView(aiModel: AIModel(mailboxManager: PreviewHelper.sampleMailboxManager), draft: Draft())
    }
}
