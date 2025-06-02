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
    @State private var isShowingEmojiPicker = false

    @Binding var selectedEmoji: Emoji?

    let reactions: [String]

    let reactionsCountForEmoji: (String) -> Int
    let isReactionEnabled: (String) -> Bool

    let didTapReaction: (String) -> Void
    let didLongPressReaction: (String) -> Void

    public init(
        selectedEmoji: Binding<Emoji?>,
        reactions: [String],
        reactionsCountForEmoji: @escaping (String) -> Int,
        isReactionEnabled: @escaping (String) -> Bool,
        didTapReaction: @escaping (String) -> Void,
        didLongPressReaction: @escaping (String) -> Void
    ) {
        _selectedEmoji = selectedEmoji
        
        self.reactions = reactions
        self.reactionsCountForEmoji = reactionsCountForEmoji
        self.isReactionEnabled = isReactionEnabled
        self.didTapReaction = didTapReaction
        self.didLongPressReaction = didLongPressReaction
    }

    public var body: some View {
        BackportedFlowLayout(verticalSpacing: IKPadding.mini, horizontalSpacing: IKPadding.mini) {
            ForEach(reactions, id: \.self) { emoji in
                ReactionButton(
                    emoji: emoji,
                    count: reactionsCountForEmoji(emoji),
                    isEnabled: isReactionEnabled(emoji),
                    didTapButton: didTapReaction,
                    didLongPressButton: didLongPressReaction
                )
            }

            Button {
                isShowingEmojiPicker = true
            } label: {
                MailResourcesAsset.faceSlightlySmilingCirclePlusSvg.swiftUIImage
                    .iconSize(.large)
            }
            .buttonStyle(.reaction(isEnabled: false, padding: EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)))
            .emojiPicker(isPresented: $isShowingEmojiPicker, selectedEmoji: $selectedEmoji)
        }
    }
}

#Preview {
    ReactionsListView(
        selectedEmoji: .constant(nil),
        reactions: ["😄", "😂"],
        reactionsCountForEmoji: { _ in 0 },
        isReactionEnabled: { _ in false },
        didTapReaction: { _ in },
        didLongPressReaction: { _ in }
    )
}
