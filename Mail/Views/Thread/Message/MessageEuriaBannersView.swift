/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

struct MessageEuriaBannersView: View {
    @Environment(\.locale) private var locale
    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var threadViewState: ThreadViewState

    @ObservedRealmObject var message: Message

    var body: some View {
        if let summaryState = threadViewState.summaries[message.uid] {
            MessageEuriaContentView(
                title: summaryState.title(contentLoaded: message.summary != nil),
                isError: summaryState == .showError
            ) {
                if let summary = message.summary {
                    Text(summary)
                        .textStyle(.bodySmall)
                } else if summaryState == .showError {
                    Button(action: summarizeMessage) {
                        Text(MailResourcesStrings.Localizable.aiButtonRetry)
                            .font(MailTextStyle.body.font)
                            .foregroundStyle(MailResourcesAsset.primaryBlueColor.swiftUIColor)
                    }
                    .padding(.leading, value: .large)
                }
            } dismiss: {
                withAnimation {
                    threadViewState.summaries[message.uid] = nil
                }
            }
            .padding(.horizontal, value: .medium)
        }

        if let translatedState = threadViewState.translatedMessages[message.uid] {
            MessageEuriaContentView(
                title: translatedState.title(contentLoaded: message.translatedBody != nil, locale: locale),
                isError: {
                    if case .showError(let error) = translatedState,
                       error != MailApiError.translationTargetSameAsSource {
                        return true
                    }
                    return false
                }()
            ) {
                if message.translatedBody?.value != nil {
                    Button {
                        withAnimation {
                            $message.isShowingTranslated.wrappedValue = false
                            threadViewState.translatedMessages[message.uid] = nil
                        }
                    } label: {
                        Text(MailResourcesStrings.Localizable.buttonShowOriginal)
                            .font(MailTextStyle.body.font)
                            .foregroundStyle(MailResourcesAsset.primaryBlueColor.swiftUIColor)
                    }
                    .padding(.leading, value: .large)
                } else if case .showError(let error) = translatedState,
                          error != MailApiError.translationTargetSameAsSource {
                    Button(action: translateMessage) {
                        Text(MailResourcesStrings.Localizable.aiButtonRetry)
                            .font(MailTextStyle.body.font)
                            .foregroundStyle(MailResourcesAsset.primaryBlueColor.swiftUIColor)
                    }
                    .padding(.leading, value: .large)
                }
            } dismiss: {
                withAnimation {
                    threadViewState.translatedMessages[message.uid] = nil
                }
            }
            .padding(.horizontal, value: .medium)
        }
    }

    private func summarizeMessage() {
        Task {
            try await mailboxManager.summarize(
                message: message.freezeIfNeeded(),
                threadViewState: threadViewState,
                locale: locale
            )
        }
    }

    private func translateMessage() {
        Task {
            try await mailboxManager.translate(
                message: message.freezeIfNeeded(),
                threadViewState: threadViewState,
                locale: locale
            )
        }
    }
}

#Preview {
    MessageEuriaBannersView(message: PreviewHelper.sampleMessage)
}
