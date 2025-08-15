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

public extension Color {
    static let reactionButtonBackground = MailResourcesAsset.hoverMenuBackground.swiftUIColor
    static let reactionButtonBackgroundEnabled = UserDefaults.shared.accentColor.secondary.swiftUIColor

    static let reactionButtonBorder = MailResourcesAsset.hoverMenuBackground.swiftUIColor
    static let reactionButtonBorderEnabled = Color.accentColor
}

public extension ButtonStyle where Self == ReactionButtonStyle {
    static func reaction(isEnabled: Bool) -> ReactionButtonStyle {
        return ReactionButtonStyle(isEnabled: isEnabled)
    }
}

public struct ReactionButtonStyle: ButtonStyle {
    private static let padding: EdgeInsets = .init(
        top: IKPadding.micro,
        leading: IKPadding.small,
        bottom: IKPadding.micro,
        trailing: IKPadding.small
    )

    private var backgroundColor: Color {
        return isEnabled ? .reactionButtonBackgroundEnabled : .reactionButtonBackground
    }

    private var borderColor: Color {
        return isEnabled ? .reactionButtonBorderEnabled : .reactionButtonBorder
    }

    private var textStyle: MailTextStyle {
        return isEnabled ? .bodyMediumAccent : .bodyMedium
    }

    let isEnabled: Bool

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(textStyle)
            .padding(Self.padding)
            .frame(minHeight: 32)
            .background(backgroundColor, in: .capsule)
            .overlay {
                Capsule()
                    .strokeBorder(borderColor)
            }
            .opacity(configuration.isPressed ? 0.3 : 1)
    }
}

#Preview {
    HStack {
        Button { /* Empty */ } label: {
            Text("😄 1")
        }
        .buttonStyle(.reaction(isEnabled: false))

        Button { /* Empty */ } label: {
            Text("🗽 3")
        }
        .buttonStyle(.reaction(isEnabled: true))
    }
}
