/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import DesignSystem
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

struct AIPropositionView: View {
    @LazyInjectService private var matomo: MatomoUtils

    @Environment(\.dismiss) private var dismiss

    @State private var textPlainHeight = CGFloat.zero
    @State private var willShowAIPrompt = false

    @ObservedObject var aiModel: AIModel

    @Namespace private var errorID

    private var secondaryButtonsTint: Color {
        if #available(iOS 26, *) {
            return .primary
        } else {
            return MailResourcesAsset.textSecondaryColor.swiftUIColor
        }
    }

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
                    .padding([.horizontal, .bottom], value: .medium)
                }
                .background(MailResourcesAsset.backgroundColor.swiftUIColor)
                .overlay(alignment: .bottom) {
                    if aiModel.currentStyle == .loading {
                        AIProgressView()
                    }
                }
                .onChange(of: aiModel.error) { error in
                    guard error != nil else { return }
                    withAnimation {
                        proxy.scrollTo(errorID)
                    }
                }
            }
            .navigationTitle(MailResourcesStrings.Localizable.aiPromptTitle)
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
                ToolbarItem(placement: .cancellationAction) {
                    ToolbarCloseButton {
                        matomo.track(eventWithCategory: .aiWriter, name: "dismissProposition")
                        dismiss()
                    }
                    .tint(secondaryButtonsTint)
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    if aiModel.currentStyle == .standard || aiModel.currentStyle == .error {
                        AIPropositionMenu(aiModel: aiModel)
                            .tint(secondaryButtonsTint)
                    }

                    Spacer()

                    switch aiModel.currentStyle {
                    case .loading:
                        if #unavailable(iOS 26.0) {
                            Text(MailResourcesStrings.Localizable.aiPromptGenerationLoader)
                                .textStyle(.bodyMediumTertiary)
                        }
                    case .standard, .error:
                        if #available(iOS 26.0, *) {
                            insertButton
                                .buttonStyle(.borderedProminent)
                        } else {
                            insertButton
                                .buttonStyle(.ikBorderedProminent)
                        }
                    case .loadingError:
                        if #available(iOS 26.0, *) {
                            retryButton
                                .buttonStyle(.borderedProminent)
                        } else {
                            retryButton
                                .buttonStyle(.ikBorderedProminent)
                        }
                    }
                }
            }
            .mailCustomAlert(isPresented: $aiModel.isShowingReplaceBodyAlert) {
                ReplaceMessageBodyView {
                    Task {
                        await aiModel.splitPropositionAndInsert(shouldReplaceBody: true)
                    }
                }
            }
            .mailCustomAlert(item: $aiModel.isShowingReplaceSubjectAlert) { proposition in
                ReplaceMessageSubjectView(subject: proposition.subject) { shouldReplaceSubject in
                    Task {
                        await aiModel.insertProposition(
                            subject: shouldReplaceSubject ? proposition.subject : nil,
                            body: proposition.body,
                            shouldReplaceBody: proposition.shouldReplaceContent
                        )
                    }
                }
            }
            .ikButtonTheme(.aiWriter)
            .tint(MailResourcesAsset.aiColor.swiftUIColor)
            .matomoView(view: ["AI", "Proposition"])
        }
    }

    private var insertButton: some View {
        Button {
            Task {
                await aiModel.didTapInsert()
            }
        } label: {
            Label {
                Text(MailResourcesStrings.Localizable.aiButtonInsert)
            } icon: {
                MailResourcesAsset.check
                    .iconSize(.medium)
            }
        }
    }

    private var retryButton: some View {
        Button(MailResourcesStrings.Localizable.aiButtonRetry) {
            matomo.track(eventWithCategory: .aiWriter, name: "retry")
            aiModel.keepConversationWhenPropositionIsDismissed = true
            willShowAIPrompt = true
            dismiss()
        }
    }
}

#Preview {
    AIPropositionView(aiModel: AIModel(
        mailboxManager: PreviewHelper.sampleMailboxManager,
        draft: Draft(),
        isReplying: false
    ))
}
