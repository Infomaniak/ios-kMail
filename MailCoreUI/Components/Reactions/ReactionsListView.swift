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
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailResources
import RealmSwift
import SwiftUI

public struct ReactionsListView: View {
    @State private var selectedReactionToDisplay: ReactionSelectionType?

    @State private var isShowingEmojiPicker = false
    @State private var selectedEmoji: Emoji?

    let reactions: [UIReaction]
    let emojiPickerButtonIsDisabled: Bool
    let addReaction: (String) -> Void
    let disabledOpenEmojiPickerButtonCompletion: (() -> Void)?

    public init(
        reactions: [UIReaction],
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
                    didTapReactionButton(reaction)
                } didLongPressButton: {
                    didLongPressReaction(reaction)
                }
            }

            Button(action: openEmojiPicker) {
                Label {
                    Text(MailResourcesStrings.Localizable.buttonAddReaction)
                } icon: {
                    MailResourcesAsset.faceSlightlySmilingCirclePlus
                        .iconSize(.large)
                }
                .labelStyle(.iconOnly)
                .padding(value: .micro)
            }
            .tint(emojiPickerButtonIsDisabled ? MailResourcesAsset.textTertiaryColor.swiftUIColor : Color.accentColor)
            .emojiPicker(isPresented: $isShowingEmojiPicker, selectedEmoji: $selectedEmoji)
            .onChange(of: selectedEmoji, perform: selectEmojiFromPicker)
        }
        .sheet(item: $selectedReactionToDisplay) { selectedReaction in
            ReactionsDetailsView(reactions: reactions, initialSelection: selectedReaction)
        }
    }

    private func didTapReactionButton(_ reaction: UIReaction) {
        @InjectService var matomo: MatomoUtils
        let eventName = reaction.hasUserReacted ? "alreadyUsedReaction" : "addReactionFromChip"
        matomo.track(eventWithCategory: .emojiReactions, name: eventName)

        addReaction(reaction.emoji)
    }

    private func openEmojiPicker() {
        @InjectService var matomo: MatomoUtils
        let eventName = emojiPickerButtonIsDisabled ? "openEmojiPickerDisabled" : "openEmojiPicker"
        matomo.track(eventWithCategory: .emojiReactions, name: eventName)

        if emojiPickerButtonIsDisabled {
            disabledOpenEmojiPickerButtonCompletion?()
            return
        }

        isShowingEmojiPicker = true
    }

    private func selectEmojiFromPicker(_ reaction: Emoji?) {
        guard let reaction else { return }

        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .emojiReactions, name: "addReactionFromEmojiPicker")

        addReaction(reaction.emoji)
        selectedEmoji = nil
    }

    private func didLongPressReaction(_ reaction: UIReaction) {
        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .emojiReactions, action: .longPress, name: "showReactionsBottomSheet")

        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.impactOccurred()

        selectedReactionToDisplay = .reaction(reaction.emoji)
    }
}

#Preview {
    ReactionsListView(reactions: PreviewHelper.uiReactions, emojiPickerButtonIsDisabled: false) { _ in }
}
