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

    @Environment(\.mailButtonPrimaryColor) private var mailButtonPrimaryColor: Color
    @Environment(\.mailButtonSecondaryColor) private var mailButtonSecondaryColor: Color
    @Environment(\.mailButtonFullWidth) private var fullWidth: Bool
    @Environment(\.mailButtonMinimizeHeight) private var minimizeHeight: Bool

    let style: MailButton.Style
    let iconOnlyButton: Bool

    private var buttonHeight: CGFloat? {
        guard !minimizeHeight else { return nil }

        if style == .floatingActionButton {
            return iconOnlyButton ? 64 : 56
        } else if fullWidth {
            return 56
        } else {
            return 40
        }
    }

    private var buttonWidth: CGFloat? {
        if style == .floatingActionButton && iconOnlyButton {
            return 64
        }
        return nil
    }

    func makeBody(configuration: Configuration) -> some View {
        switch style {
        case .large, .floatingActionButton:
            largeStyle(configuration: configuration)
        case .link, .smallLink, .destructive:
            linkStyle(configuration: configuration)
        }
    }
}

// MARK: - Large style helpers

extension MailButtonStyle {
    @ViewBuilder private func largeStyle(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(largeTextColor())
            .textStyle(.bodyMedium)
            .padding(.horizontal, value: .medium)
            .frame(width: buttonWidth, height: buttonHeight)
            .background(largeBackground(configuration: configuration))
            .clipShape(RoundedRectangle(cornerRadius: UIConstants.buttonsRadius))
            .brightness(largeBrightness(configuration: configuration))
    }

    private func largeBackground(configuration: Configuration) -> Color {
        guard isEnabled else { return MailResourcesAsset.textTertiaryColor.swiftUIColor }

        var opacity = 1.0
        if colorScheme == .light {
            opacity = configuration.isPressed ? 0.8 : 1
        }

        return mailButtonPrimaryColor.opacity(opacity)
    }

    private func largeTextColor() -> Color {
        guard isEnabled else { return MailTextStyle.bodyMediumOnDisabled.color }
        return mailButtonSecondaryColor
    }

    private func largeBrightness(configuration: Configuration) -> Double {
        guard colorScheme == .dark else { return 0 }
        return configuration.isPressed ? 0.1 : 0
    }
}

// MARK: - Link style helpers

extension MailButtonStyle {
    @ViewBuilder private func linkStyle(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(linkTextColor())
            .textStyle(linkTextStyle())
            .opacity(configuration.isPressed ? 0.7 : 1)
            .frame(width: buttonWidth, height: buttonHeight)
    }

    private func linkTextStyle() -> MailTextStyle {
        switch style {
        case .link, .destructive:
            return .bodyMedium
        case .smallLink:
            return .bodySmall
        default:
            return .body
        }
    }

    private func linkTextColor() -> Color {
        guard isEnabled else { return MailTextStyle.bodyMediumOnDisabled.color }

        if style == .destructive {
            return MailTextStyle.bodyMediumError.color
        } else {
            return mailButtonPrimaryColor
        }
    }
}
