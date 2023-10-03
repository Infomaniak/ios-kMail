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

// MARK: - Environment

struct MailButtonStyleKey: EnvironmentKey {
    static var defaultValue = MailButton.Style.large
}

struct MailButtonPrimaryColorKey: EnvironmentKey {
    static var defaultValue = Color.accentColor
}

struct MailButtonSecondaryColorKey: EnvironmentKey {
    static var defaultValue = UserDefaults.shared.accentColor.onAccent.swiftUIColor
}

struct MailButtonFullWidthKey: EnvironmentKey {
    static var defaultValue = false
}

struct MailButtonMinimizeHeightKey: EnvironmentKey {
    static var defaultValue = false
}

struct MailButtonIconSizeKey: EnvironmentKey {
    static var defaultValue: CGFloat = UIConstants.buttonsIconSize
}

struct MailButtonLoadingKey: EnvironmentKey {
    static var defaultValue = false
}

extension EnvironmentValues {
    var mailButtonStyle: MailButton.Style {
        get { self[MailButtonStyleKey.self] }
        set { self[MailButtonStyleKey.self] = newValue }
    }

    var mailButtonPrimaryColor: Color {
        get { self[MailButtonPrimaryColorKey.self] }
        set { self[MailButtonPrimaryColorKey.self] = newValue }
    }

    var mailButtonSecondaryColor: Color {
        get { self[MailButtonSecondaryColorKey.self] }
        set { self[MailButtonSecondaryColorKey.self] = newValue }
    }

    var mailButtonFullWidth: Bool {
        get { self[MailButtonFullWidthKey.self] }
        set { self[MailButtonFullWidthKey.self] = newValue }
    }

    var mailButtonMinimizeHeight: Bool {
        get { self[MailButtonMinimizeHeightKey.self] }
        set { self[MailButtonMinimizeHeightKey.self] = newValue }
    }

    var mailButtonIconSize: CGFloat {
        get { self[MailButtonIconSizeKey.self] }
        set { self[MailButtonIconSizeKey.self] = newValue }
    }

    var mailButtonLoading: Bool {
        get { self[MailButtonLoadingKey.self] }
        set { self[MailButtonLoadingKey.self] = newValue }
    }
}

extension View {
    func mailButtonStyle(_ style: MailButton.Style) -> some View {
        environment(\.mailButtonStyle, style)
    }

    func mailButtonPrimaryColor(_ color: Color) -> some View {
        environment(\.mailButtonPrimaryColor, color)
    }

    func mailButtonSecondaryColor(_ color: Color) -> some View {
        environment(\.mailButtonSecondaryColor, color)
    }

    func mailButtonFullWidth(_ fullWidth: Bool) -> some View {
        environment(\.mailButtonFullWidth, fullWidth)
    }

    func mailButtonMinimizeHeight(_ minimize: Bool) -> some View {
        environment(\.mailButtonMinimizeHeight, minimize)
    }

    func mailButtonIconSize(_ size: CGFloat) -> some View {
        environment(\.mailButtonIconSize, size)
    }

    func mailButtonLoading(_ loading: Bool) -> some View {
        environment(\.mailButtonLoading, loading)
    }
}

// MARK: - View

struct MailButton: View {
    @Environment(\.isEnabled) private var isEnabled

    @Environment(\.mailButtonStyle) private var style: Style
    @Environment(\.mailButtonFullWidth) private var fullWidth: Bool
    @Environment(\.mailButtonIconSize) private var iconSize: CGFloat
    @Environment(\.mailButtonLoading) private var loading: Bool

    var icon: MailResourcesImages?
    var label: String?

    let action: () -> Void

    enum Style {
        case floatingActionButton, large, link, smallLink, destructive
    }

    private var iconOnlyButton: Bool {
        return label == nil
    }

    var body: some View {
        Button(role: style == .destructive ? .destructive : nil, action: action) {
            ZStack {
                HStack(spacing: UIPadding.small) {
                    if let icon {
                        icon.swiftUIImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: iconSize, height: iconSize)
                    }
                    if let label {
                        Text(label)
                    }
                }
                .opacity(loading ? 0 : 1)

                LoadingButtonProgressView(style: style)
                    .opacity(loading ? 1 : 0)
            }
            .frame(maxWidth: fullWidth ? UIConstants.componentsMaxWidth : nil)
        }
        .disabled(loading || !isEnabled)
        .buttonStyle(MailButtonStyle(style: style, iconOnlyButton: iconOnlyButton))
        .animation(.easeOut(duration: 0.25), value: isEnabled)
    }
}

struct MailButton_Previews: PreviewProvider {
    @available(iOS 16.0, *)
    private static var buttonsRow: some View {
        GridRow {
            MailButton(label: "Link") { /* Preview */ }
                .mailButtonStyle(.link)
            MailButton(label: "Large") { /* Preview */ }
            MailButton(label: "Small Link") { /* Preview */ }
                .mailButtonStyle(.smallLink)

            MailButton(icon: MailResourcesAsset.synchronizeArrow, label: "Link") { /* Preview */ }
                .mailButtonStyle(.link)
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

                buttonsRow
                    .mailButtonLoading(true)

                GridRow {
                    MailButton(label: "Link") { /* Preview */ }
                        .mailButtonStyle(.destructive)
                }

                GridRow {
                    MailButton(icon: MailResourcesAsset.pencilPlain, label: "Full Width") { /* Preview */ }
                        .mailButtonFullWidth(true)
                        .frame(maxWidth: .infinity)
                }
                .gridCellColumns(6)
            }
            .previewInterfaceOrientation(.landscapeLeft)
        }
    }
}
