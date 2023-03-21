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

// MARK: - Modifiers

struct MailButtonStyleKey: EnvironmentKey {
    static var defaultValue = MailButton.Style.large
}

struct MailButtonFullWidthKey: EnvironmentKey {
    static var defaultValue = false
}

struct MailButtonIconSizeKey: EnvironmentKey {
    static var defaultValue: CGFloat = Constants.buttonsIconSize
}

struct MailButtonLoadingKey: EnvironmentKey {
    static var defaultValue = false
}

extension EnvironmentValues {
    var mailButtonStyle: MailButton.Style {
        get { self[MailButtonStyleKey.self] }
        set { self[MailButtonStyleKey.self] = newValue }
    }

    var mailButtonFullWidth: Bool {
        get { self[MailButtonFullWidthKey.self] }
        set { self[MailButtonFullWidthKey.self] = newValue }
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

    func mailButtonFullWidth(_ fullWidth: Bool) -> some View {
        environment(\.mailButtonFullWidth, fullWidth)
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
        case large, link, smallLink, destructive
    }

    var body: some View {
        Button(role: style == .destructive ? .destructive : nil, action: action) {
            ZStack {
                HStack(spacing: 8) {
                    if let icon {
                        icon.swiftUIImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: iconSize, height: iconSize)
                            .padding(.vertical, 2)
                    }
                    if let label {
                        Text(label)
                    }
                }
                .opacity(loading ? 0 : 1)
                if loading {
                    LoadingButtonProgressView(style: style)
                }
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
        }
        .disabled(loading || !isEnabled)
        .buttonStyle(MailButtonStyle(style: style))
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
