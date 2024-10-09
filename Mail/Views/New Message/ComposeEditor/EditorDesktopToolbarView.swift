/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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

import InfomaniakCoreSwiftUI
import InfomaniakRichHTMLEditor
import MailCore
import MailCoreUI
import MailResources
import Popovers
import SwiftUI

struct EditorDesktopToolbarView: View {
    @Binding var isShowingLinkAlert: Bool
    @Binding var isShowingFileSelection: Bool

    @ObservedObject var textAttributes: TextAttributes

    private static let extras: [EditorToolbarAction] = [
        .addFile,
        .link
    ]

    private static let textFormats: [EditorToolbarAction] = [
        .bold,
        .underline,
        .italic,
        .strikeThrough,
        .cancelFormat
    ]

    private static let textItems: [EditorToolbarAction] = [
        .unorderedList
    ]

    private static let allItems: [[EditorToolbarAction]] = [extras, textFormats, textItems]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: IKPadding.extraSmall) {
                ForEach(EditorDesktopToolbarView.allItems, id: \.self) { items in
                    ForEach(items) { item in
                        Button {
                            item.action(
                                textAttributes: textAttributes,
                                isShowingLinkAlert: $isShowingLinkAlert,
                                isShowingFileSelection: $isShowingFileSelection
                            )
                        } label: {
                            item.icon.swiftUIImage
                                .iconSize(.medium)
                                .padding(value: .small)
                        }
                        .buttonStyle(.macosToolbarButtonStyle(isActive: item.isSelected(textAttributes: textAttributes)))
                        .help(item.accessibilityLabel)
                        .keyboardToolbarShortcut(item.keyboardShortcut)
                    }

                    if EditorDesktopToolbarView.allItems.last != items {
                        Divider()
                            .overlay(MailResourcesAsset.elementsColor.swiftUIColor)
                            .frame(width: 1, height: 16)
                    }
                }
            }
            .padding(.vertical, value: .extraSmall)
            .padding(.horizontal, IKPadding.composeViewHeaderHorizontal)

            IKDivider()
        }
    }
}

struct DesktopToolbarButtonStyle: ButtonStyle {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @State private var isHovered = false

    let isActive: Bool

    var backgroundColor: Color {
        if isActive {
            return accentColor.secondary.swiftUIColor
        }
        if isHovered {
            return MailResourcesAsset.hoverMenuBackground.swiftUIColor
        }
        return .clear
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(backgroundColor)
            .foregroundStyle(MailResourcesAsset.toolbarForegroundColor.swiftUIColor)
            .cornerRadius(2)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension ButtonStyle where Self == DesktopToolbarButtonStyle {
    static func macosToolbarButtonStyle(isActive: Bool) -> DesktopToolbarButtonStyle {
        DesktopToolbarButtonStyle(isActive: isActive)
    }
}
