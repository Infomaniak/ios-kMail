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

public struct ReactionsListView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @State private var selectedReactionToDisplay: ReactionSelectionType?

    @State private var isShowingEmojiPicker = false
    @State private var selectedEmoji: Emoji?

    let reactions: [UIMessageReaction]
    let emojiPickerButtonIsDisabled: Bool
    let addReaction: (String) -> Void
    let disabledOpenEmojiPickerButtonCompletion: (() -> Void)?

    public init(
        reactions: [UIMessageReaction],
        emojiPickerButtonIsDisabled: Bool,
        addReaction: @escaping (String) -> Void,
        disabledOpenEmojiPickerButtonCompletion: (() -> Void)? = nil
    ) {
        self.reactions = reactions
        self.emojiPickerButtonIsDisabled = emojiPickerButtonIsDisabled
        self.addReaction = addReaction
        self.disabledOpenEmojiPickerButtonCompletion = disabledOpenEmojiPickerButtonCompletion
    }

    public var body: some View {
        BackportedFlowLayout(verticalSpacing: IKPadding.mini, horizontalSpacing: IKPadding.mini) {
            ForEach(reactions) { reaction in
                ReactionButton(reaction: reaction) {
                    addReaction(reaction.emoji)
                } didLongPressButton: {
                    didLongPressReaction(reaction)
                }
            }

            Button(action: openEmojiPicker) {
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
        .sheet(item: $selectedReactionToDisplay) { selectedReaction in
            if #available(iOS 16, *) {
                ReactionsDetailsView(reactions: reactions, initialSelection: selectedReaction)
            } else {
                ReactionsDetailsBackportView(reactions: reactions, initialSelection: selectedReaction)
            }
        }
    }

    private func openEmojiPicker() {
        if emojiPickerButtonIsDisabled {
            disabledOpenEmojiPickerButtonCompletion?()
            return
        }

        isShowingEmojiPicker = true
    }

    private func selectEmojiFromPicker(_ reaction: Emoji?) {
        guard let reaction else { return }

        addReaction(reaction.emoji)
        selectedEmoji = nil
    }

    private func didLongPressReaction(_ reaction: UIMessageReaction) {
        selectedReactionToDisplay = .reaction(reaction.emoji)
    }
}

#Preview {
    ReactionsListView(reactions: PreviewHelper.uiReactions, emojiPickerButtonIsDisabled: false) { _ in }
}
