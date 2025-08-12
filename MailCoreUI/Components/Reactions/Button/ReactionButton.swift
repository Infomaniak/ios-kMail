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

struct BackportNumericContentTransition: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .contentTransition(.numericText())
        } else {
            content
        }
    }
}

extension View {
    func backportNumericContentTransition() -> some View {
        modifier(BackportNumericContentTransition())
    }
}

struct ReactionButton: View {
    let emoji: String
    let count: Int
    let hasReacted: Bool

    let didTapButton: () -> Void
    let didLongPressButton: () -> Void

    var body: some View {
        Button {} label: {
            HStack(spacing: 2) {
                Text(verbatim: emoji)
                Text(verbatim: "\(count)")
                    .monospacedDigit()
                    .backportNumericContentTransition()
                    .animation(.default, value: count)
            }
        }
        .buttonStyle(.reaction(isEnabled: hasReacted))
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in didTapButton() }
        )
        .simultaneousGesture(
            LongPressGesture()
                .onEnded { _ in didLongPressButton() }
        )
    }
}

#Preview {
    HStack {
        ReactionButton(
            emoji: "😄",
            count: 2,
            hasReacted: false,
            didTapButton: { },
            didLongPressButton: { }
        )
        ReactionButton(
            emoji: "❤️",
            count: 4,
            hasReacted: true,
            didTapButton: { },
            didLongPressButton: { }
        )
    }
}
