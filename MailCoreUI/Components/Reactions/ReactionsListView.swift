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
import RealmSwift
import SwiftUI

public struct ReactionsListView: View {
    let reactions: [String]

    let reactionsCountForEmoji: (String) -> Int
    let isReactionEnabled: (String) -> Bool

    let didTapButton: (String) -> Void
    let didLongPressButton: (String) -> Void

    public init(
        reactions: [String],
        reactionsCountForEmoji: @escaping (String) -> Int,
        isReactionEnabled: @escaping (String) -> Bool,
        didTapButton: @escaping (String) -> Void,
        didLongPressButton: @escaping (String) -> Void
    ) {
        self.reactions = reactions
        self.reactionsCountForEmoji = reactionsCountForEmoji
        self.isReactionEnabled = isReactionEnabled
        self.didTapButton = didTapButton
        self.didLongPressButton = didLongPressButton
    }

    public var body: some View {
        BackportedFlowLayout(reactions, id: \.self, verticalSpacing: IKPadding.mini, horizontalSpacing: IKPadding.mini) { emoji in
            ReactionButton(
                emoji: emoji,
                count: reactionsCountForEmoji(emoji),
                hasReacted: isReactionEnabled(emoji),
                didTapButton: didTapButton,
                didLongPressButton: didLongPressButton
            )
        }
    }

}

#Preview {
    ReactionsListView(
        reactions: ["😄", "😂"],
        reactionsCountForEmoji: { _ in 0 },
        isReactionEnabled: { _ in false },
        didTapButton: { _ in },
        didLongPressButton: { _ in }
    )
}
