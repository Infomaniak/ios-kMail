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

    let reactions: [String: Set<Recipient>]
    let didTapReaction: (String) -> Void

    public init(
        selectedEmoji: Binding<Emoji?>,
        reactions: [String: Set<Recipient>],
        didTapReaction: @escaping (String) -> Void
    ) {
        _selectedEmoji = selectedEmoji
        
        self.reactions = reactions
        self.didTapReaction = didTapReaction
    }

    public var body: some View {
        BackportedFlowLayout(verticalSpacing: IKPadding.mini, horizontalSpacing: IKPadding.mini) {
            ForEach(Array(reactions.keys), id: \.self) { emoji in
                ReactionButton(
                    emoji: emoji,
                    count: reactions[emoji]?.count ?? 0,
                    hasReacted: false,
                    didTapButton: didTapReaction,
                    didLongPressButton: didLongPressReaction
                )
            }

            Button {
                isShowingEmojiPicker = true
            } label: {
                MailResourcesAsset.faceSlightlySmilingCirclePlus.swiftUIImage
                    .iconSize(.large)
            }
            .buttonStyle(.reaction(isEnabled: false, padding: EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)))
            .emojiPicker(isPresented: $isShowingEmojiPicker, selectedEmoji: $selectedEmoji)
        }
    }

    private func didLongPressReaction(_ reaction: String) -> Void {

    }
}

#Preview {
    ReactionsListView(
        selectedEmoji: .constant(nil),
        reactions: [
            "😄": [PreviewHelper.sampleRecipient1],
            "😂": [PreviewHelper.sampleRecipient1, PreviewHelper.sampleRecipient2]
        ],
        didTapReaction: { _ in }
    )
}
