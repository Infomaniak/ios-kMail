/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import MailCore
import MailResources
import SwiftUI

struct MailButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled

    let style: MailButton.Style

    func makeBody(configuration: Configuration) -> some View {
        switch style {
        case .large:
            largeStyle(configuration: configuration)
        case .link, .smallLink, .destructive:
            linkStyle(configuration: configuration)
        }
    }

    @ViewBuilder private func largeStyle(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(isEnabled ? .bodyMediumOnAccent : .bodyMediumOnDisabled)
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .background(largeBackground(configuration: configuration))
            .clipShape(RoundedRectangle(cornerRadius: UIConstants.buttonsRadius))
            .brightness(largeBrightness(configuration: configuration))
            .frame(maxWidth: 496, alignment: .trailing)
    }

    @ViewBuilder private func linkStyle(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(linkTextStyle())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }

    private func largeBackground(configuration: Configuration) -> Color {
        guard isEnabled else { return MailResourcesAsset.textTertiaryColor.swiftUIColor }

        var opacity = 1.0
        if colorScheme == .light {
            opacity = configuration.isPressed ? 0.8 : 1
        }
        return .accentColor.opacity(opacity)
    }

    private func largeBrightness(configuration: Configuration) -> Double {
        guard colorScheme == .dark else { return 0 }
        return configuration.isPressed ? 0.1 : 0
    }

    private func linkTextStyle() -> MailTextStyle {
        switch style {
        case .link:
            return .bodyMediumAccent
        case .smallLink:
            return .bodySmallAccent
        case .destructive:
            return .bodyMediumError
        default:
            return .body
        }
    }
}
