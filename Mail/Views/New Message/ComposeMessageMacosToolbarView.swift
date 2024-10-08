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

struct ComposeMessageMacosToolbarView: View {
    @Binding var isShowingLinkAlert: Bool
    @Binding var isShowingFileSelection: Bool

    @ObservedObject var textAttributes: TextAttributes

    private static let extras: [EditorToolbarAction] = [
        .attachment,
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
                ForEach(ComposeMessageMacosToolbarView.allItems, id: \.self) { items in
                    ForEach(items) { item in
                        Button {
                            item.action(
                                textAttributes: textAttributes,
                                isShowingLinkAlert: $isShowingLinkAlert,
                                isShowingFileSelection: $isShowingFileSelection
                            )
                        } label: {
                            item.icon.swiftUIImage
                                .resizable()
                                .iconSize(.medium)
                                .padding(value: .small)
                        }
                        .buttonStyle(.macosToolbarButtonStyle(isActive: item.isSelected(textAttributes: textAttributes)))
                        .help(item.accessibilityLabel)
                        .keyboardToolbarShortcut(item.keyboardShortcut)
                    }

                    if ComposeMessageMacosToolbarView.allItems.last != items {
                        Divider()
                            .padding(.vertical, value: .medium)
                    }
                }
            }
            .padding(.vertical, IKPadding.extraSmall)
            .padding(.horizontal, IKPadding.composeViewHeaderHorizontal)

            IKDivider()
        }
    }
}

struct MacosToolbarButtonStyle: ButtonStyle {
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
            .foregroundColor(.primary)
            .cornerRadius(2)
            .onHover { hovering in
                withAnimation {
                    isHovered = hovering
                }
            }
    }
}

extension ButtonStyle where Self == MacosToolbarButtonStyle {
    static func macosToolbarButtonStyle(isActive: Bool) -> MacosToolbarButtonStyle {
        MacosToolbarButtonStyle(isActive: isActive)
    }
}
