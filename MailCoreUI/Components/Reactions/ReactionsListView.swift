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
import ElegantEmojiPicker
import MailCore
import MailResources
import RealmSwift
import SwiftUI

public struct UIMessageReaction: Identifiable {
    public var id: String { emoji }

    public let emoji: String
    public let recipients: [Recipient]

    public init(reaction: String, recipients: [Recipient]) {
        self.emoji = reaction
        self.recipients = recipients
    }
}

public struct ReactionsListView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var isShowingEmojiPicker = false

    @Binding var selectedEmoji: Emoji?

    let reactions: [UIMessageReaction]
    let didTapReaction: (String) -> Void

    public init(selectedEmoji: Binding<Emoji?>, reactions: [UIMessageReaction], didTapReaction: @escaping (String) -> Void) {
        _selectedEmoji = selectedEmoji

        self.reactions = reactions
        self.didTapReaction = didTapReaction
    }

    public var body: some View {
        BackportedFlowLayout(verticalSpacing: IKPadding.mini, horizontalSpacing: IKPadding.mini) {
            ForEach(reactions) { reaction in
                ReactionButton(
                    reaction: reaction,
                    hasReacted: hasCurrentUserReacted(to: reaction.emoji),
                    didTapButton: didTapReaction,
                    didLongPressButton: didLongPressReaction
                )
            }

            Button {
                isShowingEmojiPicker = true
            } label: {
                Label {
                    Text(MailResourcesStrings.Localizable.contentDescriptionAddReaction)
                } icon: {
                    MailResourcesAsset.faceSlightlySmilingCirclePlus.swiftUIImage
                        .iconSize(.large)
                }
                .labelStyle(.iconOnly)
            }
            .buttonStyle(.reaction(isEnabled: false, padding: EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)))
            .emojiPicker(isPresented: $isShowingEmojiPicker, selectedEmoji: $selectedEmoji)
        }
    }

    private func didLongPressReaction(_ reaction: String) {}

    private func hasCurrentUserReacted(to reaction: String) -> Bool {
        return false
    }
}

#Preview {
    ReactionsListView(
        selectedEmoji: .constant(nil),
        reactions: [
            UIMessageReaction(reaction: "😄", recipients: [PreviewHelper.sampleRecipient1]),
            UIMessageReaction(reaction: "😂", recipients: [PreviewHelper.sampleRecipient1, PreviewHelper.sampleRecipient2])
        ],
        didTapReaction: { _ in }
    )
}
