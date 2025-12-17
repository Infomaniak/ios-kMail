/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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
import InfomaniakCore
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftUI

extension EnvironmentValues {
    @Entry
    var isMessageInteractive = true
}

/// Something that can display an email
struct MessageView: View {
    @LazyInjectService private var featureAvailableProvider: FeatureAvailableProvider

    @Environment(\.isMessageInteractive) private var isMessageInteractive

    @State private var displayContentBlockedActionView = false
    @State private var initialContentLoading = true

    @Binding var threadForcedExpansion: [String: MessageExpansionType]

    @ObservedRealmObject var message: Message

    private var isRemoteContentBlocked: Bool {
        return (UserDefaults.shared.displayExternalContent == .askMe || message.folder?.role == .spam)
            && !message.localSafeDisplay
    }

    private var isMessageExpanded: Bool {
        threadForcedExpansion[message.uid] == .expanded
    }

    var body: some View {
        VStack(spacing: 0) {
            MessageHeaderView(
                message: message,
                isMessageExpanded: Binding(get: {
                    isMessageExpanded
                }, set: { newValue in
                    guard threadForcedExpansion.count > 1 else { return }
                    threadForcedExpansion[message.uid] = newValue ? .expanded : .collapsed
                })
            )

            if isMessageExpanded {
                VStack(spacing: IKPadding.medium) {
                    MessageSubHeaderView(
                        message: message,
                        displayContentBlockedActionView: $displayContentBlockedActionView
                    )

                    VStack(alignment: .leading, spacing: IKPadding.small) {
                        MessageBodyView(
                            displayContentBlockedActionView: $displayContentBlockedActionView,
                            initialContentLoading: $initialContentLoading,
                            isRemoteContentBlocked: isRemoteContentBlocked,
                            messageUid: message.uid
                        )

                        if featureAvailableProvider.isAvailable(.emojiReaction) && !initialContentLoading {
                            MessageReactionsView(
                                messageUid: message.uid,
                                emojiReactionNotAllowedReason: message.emojiReactionNotAllowedReason,
                                messageReactions: message.reactions
                            )
                            .padding([.horizontal, .bottom], value: .medium)
                        }
                    }
                }
            }
        }
        .accessibilityAction(named: MailResourcesStrings.Localizable.expandMessage) {
            guard isMessageInteractive else { return }
            withAnimation {
                threadForcedExpansion[message.uid] = isMessageExpanded ? .collapsed : .expanded
            }
        }
    }
}

@available(iOS 17.0, *)
#Preview("Message collapsed", traits: .sizeThatFitsLayout) {
    MessageView(
        threadForcedExpansion: .constant([PreviewHelper.sampleMessage.uid: .collapsed]),
        message: PreviewHelper.sampleMessage
    )
    .environmentObject(PreviewHelper.sampleMailboxManager)
    .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}

@available(iOS 17.0, *)
#Preview("Message expanded", traits: .sizeThatFitsLayout) {
    MessageView(
        threadForcedExpansion: .constant([PreviewHelper.sampleMessage.uid: .expanded]),
        message: PreviewHelper.sampleMessage
    )
    .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
    .environmentObject(PreviewHelper.sampleMailboxManager)
    .environmentObject(MessagesWorker(mailboxManager: PreviewHelper.sampleMailboxManager))
    .environment(\.currentUser, MandatoryEnvironmentContainer(value: PreviewHelper.sampleUser))
}
