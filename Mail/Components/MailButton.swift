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

struct MailButtonStyleKey: EnvironmentKey {
    static var defaultValue = MailButton.Style.large
}

extension EnvironmentValues {
    var mailButtonStyle: MailButton.Style {
        get { self[MailButtonStyleKey.self] }
        set { self[MailButtonStyleKey.self] = newValue }
    }
}

struct MailButtonStyle: ButtonStyle {
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
            .textStyle(.bodyMediumOnAccent)
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .background(largeBackground(configuration: configuration))
            .clipShape(RoundedRectangle(cornerRadius: Constants.buttonsRadius))
    }

    @ViewBuilder private func linkStyle(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(linkTextStyle())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }

    private func largeBackground(configuration: Configuration) -> Color {
        guard isEnabled else { return MailResourcesAsset.elementsColor.swiftUIColor }
        return .accentColor.opacity(configuration.isPressed ? 0.7 : 1)
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

extension View {
    func mailButton(style: MailButton.Style) -> some View {
        environment(\.mailButtonStyle, style)
    }
}

struct MailButton: View {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.mailButtonStyle) private var style: Style

    var icon: MailResourcesImages?
    var label: String?
    var fullWidth = false

    let action: () -> Void

    enum Style {
        case large, link, smallLink, destructive
    }

    var body: some View {
        Button(role: style == .destructive ? .destructive : nil, action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(resource: icon)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .padding(.vertical, 2)
                }
                if let label {
                    Text(label)
                }
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
        }
        .buttonStyle(MailButtonStyle(style: style))
        .animation(.easeOut(duration: 0.25), value: isEnabled)
    }
}

struct MailButton_Previews: PreviewProvider {
    @available(iOS 16.0, *)
    private static var buttonsRow: some View {
        GridRow {
            MailButton(label: "Link") { /* Preview */ }
                .mailButton(style: .link)
            MailButton(label: "Large") { /* Preview */ }
            MailButton(label: "Small Link") { /* Preview */ }
                .mailButton(style: .smallLink)

            MailButton(icon: MailResourcesAsset.synchronizeArrow, label: "Link") { /* Preview */ }
                .mailButton(style: .link)
            MailButton(icon: MailResourcesAsset.pencilPlain, label: "Large") { /* Preview */ }
            MailButton(icon: MailResourcesAsset.pencilPlain) { /* Preview */ }
        }
    }

    static var previews: some View {
        if #available(iOS 16.0, *) {
            Grid(alignment: .leading, horizontalSpacing: 30, verticalSpacing: 20) {
                buttonsRow

                buttonsRow
                    .disabled(true)

                GridRow {
                    MailButton(label: "Link") { /* Preview */ }
                        .mailButton(style: .destructive)
                }

                GridRow {
                    MailButton(icon: MailResourcesAsset.pencilPlain, label: "Full Width", fullWidth: true) { /* Preview */ }
                        .frame(maxWidth: .infinity)
                }
                .gridCellColumns(6)
            }
            .previewInterfaceOrientation(.landscapeLeft)
        }
    }
}
