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

struct ReactionButton: View {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @State private var didReactLocally = false

    let emoji: String
    let count: Int
    let hasReacted: Bool

    private var isEnabled: Bool {
        return hasReacted || didReactLocally
    }

    private var backgroundColor: Color {
        return isEnabled ? accentColor.secondary.swiftUIColor : MailResourcesAsset.hoverMenuBackground.swiftUIColor
    }

    private var borderColor: Color {
        return isEnabled ? accentColor.primary.swiftUIColor : MailResourcesAsset.hoverMenuBackground.swiftUIColor
    }

    var body: some View {
        Button {} label: {
            Text(verbatim: "\(emoji) \(count)")
                .textStyle(.bodyMedium)
                .padding(.horizontal, value: .small)
                .padding(.vertical, value: .mini)
                .background(backgroundColor, in: .capsule)
                .overlay {
                    Capsule()
                        .stroke(borderColor)
                }
        }
        .simultaneousGesture(
            TapGesture().onEnded { _ in didTapButton() }
        )
        .simultaneousGesture(
            LongPressGesture().onEnded { _ in didLongPressButton() }
        )
    }

    private func didTapButton() {
        print("Tap")
        didReactLocally = true
    }

    private func didLongPressButton() {
        print("Long Press")
    }
}

#Preview {
    HStack {
        ReactionButton(emoji: "😄", count: 1, hasReacted: false)
        ReactionButton(emoji: "❤️", count: 12, hasReacted: true)
        ReactionButton(emoji: "🤯", count: 2, hasReacted: false)
    }
}
