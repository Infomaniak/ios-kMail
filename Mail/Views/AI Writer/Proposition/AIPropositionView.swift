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

    @State private var textPlainHeight = CGFloat.zero
    @State private var willShowAIPrompt = false

    @ObservedObject var aiModel: AIModel

    @Namespace private var errorID

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    Group {
                        AIDismissibleErrorView(error: aiModel.error)
                            .id(errorID)

                        SelectableTextView(
                            textPlainHeight: $textPlainHeight,
                            text: aiModel.lastMessage,
                            style: aiModel.currentStyle
                        )
                        .frame(height: textPlainHeight)
                        .tint(MailResourcesAsset.aiColor.swiftUIColor)
                    }
                    .padding([.horizontal, .bottom], value: .regular)
                }
                .background(MailResourcesAsset.backgroundColor.swiftUIColor)
                .onChange(of: aiModel.error) { error in
                    guard error != nil else { return }
                    withAnimation {
                        proxy.scrollTo(errorID)
                    }
                }
            }
            .task {
                await aiModel.createConversation()
            }
            .onDisappear {
                if willShowAIPrompt {
                    aiModel.isShowingPrompt = true
                }
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
                        if aiModel.currentStyle == .standard || aiModel.currentStyle == .error {
                            AIPropositionMenu(aiModel: aiModel)
                        }

                        Spacer()

                        switch aiModel.currentStyle {
                        case .loading:
                            AIProgressView()
                        case .standard, .error:
                            MailButton(icon: MailResourcesAsset.plus, label: MailResourcesStrings.Localizable.aiButtonInsert) {
                                aiModel.didTapInsert()
                            }
                        case .loadingError:
                            MailButton(label: MailResourcesStrings.Localizable.aiButtonRetry) {
                                matomo.track(eventWithCategory: .aiWriter, name: "retry")
                                willShowAIPrompt = true
                                dismiss()
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
            .customAlert(isPresented: $aiModel.isShowingReplaceBodyAlert) {
                ReplaceMessageBodyView {
                    aiModel.splitPropositionAndInsert(shouldReplaceBody: true)
                }
            }
            .customAlert(item: $aiModel.isShowingReplaceSubjectAlert) { proposition in
                ReplaceMessageSubjectView(subject: proposition.subject) { shouldReplaceSubject in
                    aiModel.insertProposition(
                        subject: shouldReplaceSubject ? proposition.subject : nil,
                        body: proposition.body,
                        shouldReplaceBody: proposition.shouldReplaceContent
                    )
                }
            }
            .mailButtonPrimaryColor(MailResourcesAsset.aiColor.swiftUIColor)
            .mailButtonSecondaryColor(MailResourcesAsset.backgroundSecondaryColor.swiftUIColor)
            .tint(MailResourcesAsset.aiColor.swiftUIColor)
            .matomoView(view: ["AI", "Proposition"])
        }
    }
}

#Preview {
    AIPropositionView(
        aiModel: AIModel(mailboxManager: PreviewHelper.sampleMailboxManager,
                         draftContentManager: PreviewHelper.sampleDraftContentManager,
                         messageReply: nil)
    )
}
