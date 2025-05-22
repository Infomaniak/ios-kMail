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
import MailResources
import SwiftUI

extension Color {
    public static let reactionButtonBackground = MailResourcesAsset.hoverMenuBackground.swiftUIColor
    public static let reactionButtonBackgroundEnabled = UserDefaults.shared.accentColor.secondary.swiftUIColor

    public static let reactionButtonBorder = MailResourcesAsset.hoverMenuBackground.swiftUIColor
    public static let reactionButtonBorderEnabled = Color.accentColor
}

struct ReactionButton: View {
    let emoji: String
    let count: Int
    let hasReacted: Bool

    let didTapButton: (String) -> Void
    let didLongPressButton: (String) -> Void

    private var backgroundColor: Color {
        return hasReacted ? .reactionButtonBackgroundEnabled : .reactionButtonBackground
    }

    private var borderColor: Color {
        return hasReacted ? .reactionButtonBorderEnabled : .reactionButtonBorder
    }

    private var textStyle: MailTextStyle {
        return hasReacted ? .bodyMediumAccent : .bodyMedium
    }

    var body: some View {
        Button {} label: {
            HStack(spacing: IKPadding.micro) {
                Text(verbatim: emoji)
                Text(verbatim: "\(count)")
            }
            .textStyle(textStyle)
            .padding(.horizontal, value: .small)
            .padding(.vertical, value: .mini)
            .background(backgroundColor, in: .capsule)
            .overlay {
                Capsule()
                    .stroke(borderColor)
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded { _ in didTapButton(emoji) }
        )
        .simultaneousGesture(
            LongPressGesture().onEnded { _ in didLongPressButton(emoji) }
        )
    }
}

#Preview {
    HStack {
        ReactionButton(emoji: "😄", count: 1, hasReacted: false, didTapButton: { _ in }, didLongPressButton: { _ in })
        ReactionButton(emoji: "❤️", count: 12, hasReacted: true, didTapButton: { _ in }, didLongPressButton: { _ in })
        ReactionButton(emoji: "🤯", count: 2, hasReacted: false, didTapButton: { _ in }, didLongPressButton: { _ in })
    }
}
