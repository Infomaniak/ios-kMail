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

import DesignSystem
import InfomaniakCoreSwiftUI
import InfomaniakDI
import InfomaniakRichHTMLEditor
import MailCore
import MailCoreUI
import MailResources
import Popovers
import SwiftUI

struct EditorDesktopToolbarView: View {
    @InjectService private var featureFlagsManageable: FeatureFlagsManageable

    @Binding var isShowingLinkAlert: Bool
    @Binding var isShowingFileSelection: Bool
    @Binding var isShowingAI: Bool

    @ObservedObject var textAttributes: TextAttributes

    private let extras: [EditorToolbarAction] = [
        .addFile,
        .link
    ]

    private let textFormats: [EditorToolbarAction] = [
        .bold,
        .underline,
        .italic,
        .strikeThrough,
        .cancelFormat
    ]

    private let textItems: [EditorToolbarAction] = [
        .unorderedList
    ]

    private var allItems: [[EditorToolbarAction]] {
        var mainItems = [extras, textFormats, textItems]

        featureFlagsManageable.feature(.aiMailComposer, on: {
            mainItems.insert([.ai], at: 0)
        }, off: nil)

        return mainItems
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: IKPadding.micro) {
                ForEach(allItems, id: \.self) { items in
                    ForEach(items) { item in
                        Button {
                            item.action(
                                textAttributes: textAttributes,
                                isShowingLinkAlert: $isShowingLinkAlert,
                                isShowingFileSelection: $isShowingFileSelection,
                                isShowingAI: $isShowingAI
                            )
                        } label: {
                            item.icon.swiftUIImage
                                .iconSize(.medium)
                                .padding(value: .mini)
                        }
                        .buttonStyle(.macosToolbarButtonStyle(isActive: item.isSelected(textAttributes: textAttributes)))
                        .foregroundStyle(item.foregroundStyle)
                        .help(item.accessibilityLabel)
                        .keyboardToolbarShortcut(item.keyboardShortcut)
                    }

                    if allItems.last != items {
                        Divider()
                            .overlay(MailResourcesAsset.elementsColor.swiftUIColor)
                            .frame(width: 1, height: 16)
                    }
                }
            }
            .padding(.vertical, value: .micro)
            .padding(.horizontal, IKPadding.composeViewHeaderHorizontal)

            IKDivider()
        }
    }
}

struct DesktopToolbarButtonStyle: ButtonStyle {
    @AppStorage(UserDefaults.shared.key(.accentColor)) private var accentColor = DefaultPreferences.accentColor

    @State private var isHovered = false

    let isActive: Bool

    private var backgroundColor: Color {
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
