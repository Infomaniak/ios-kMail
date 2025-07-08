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
    public let hasUserReacted: Bool

    public init(reaction: String, recipients: [Recipient], hasUserReacted: Bool) {
        self.emoji = reaction
        self.recipients = recipients
        self.hasUserReacted = hasUserReacted
    }
}

public struct ReactionsListView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var isShowingEmojiPicker = false
    @State private var selectedEmoji: Emoji?

    let reactions: [UIMessageReaction]
    let localReactions: Set<String>
    let addReaction: (String) -> Void

    public init(reactions: [UIMessageReaction], localReactions: Set<String>, addReaction: @escaping (String) -> Void) {
        self.reactions = reactions
        self.localReactions = localReactions
        self.addReaction = addReaction
    }

    public var body: some View {
        BackportedFlowLayout(verticalSpacing: IKPadding.mini, horizontalSpacing: IKPadding.mini) {
            ForEach(reactions) { reaction in
                ReactionButton(
                    emoji: reaction.emoji,
                    count: emojiCount(for: reaction),
                    hasReacted: hasCurrentUserReacted(to: reaction),
                    didTapButton: addReaction,
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
            .onChange(of: selectedEmoji, perform: selectEmojiFromPicker)
        }
    }

    private func emojiCount(for reaction: UIMessageReaction) -> Int {
        var count = reaction.recipients.count
        if localReactions.contains(reaction.emoji)
                && !reaction.recipients.contains(where: { $0.isMe(currentMailboxEmail: mailboxManager.mailbox.email) }) {
            count += 1
        }

        return count
    }

    private func selectEmojiFromPicker(_ reaction: Emoji?) {
        guard let reaction else { return }

        addReaction(reaction.emoji)
        selectedEmoji = nil
    }

    private func didLongPressReaction(_ reaction: String) {}

    private func hasCurrentUserReacted(to reaction: UIMessageReaction) -> Bool {
        return localReactions.contains(reaction.emoji) || reaction.hasUserReacted
    }
}

#Preview {
    ReactionsListView(
        reactions: [
            UIMessageReaction(
                reaction: "😄",
                recipients: [PreviewHelper.sampleRecipient1],
                hasUserReacted: false
            ),
            UIMessageReaction(
                reaction: "😂",
                recipients: [PreviewHelper.sampleRecipient1, PreviewHelper.sampleRecipient2],
                hasUserReacted: false
            )
        ],
        localReactions: Set()
    ) { _ in }
}
