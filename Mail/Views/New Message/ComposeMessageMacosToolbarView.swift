//
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
import MailCoreUI
import MailResources
import Popovers
import SwiftUI

struct ComposeMessageMacosToolbarView: View {
    @ObservedObject public var textAttributes: TextAttributes
    @Binding var isShowingLinkAlert: Bool
    @Binding var isShowingFileSelection: Bool

    let extras: [EditorToolbarAction] = [
        .attachment,
        .link
    ]

    let textFormats: [EditorToolbarAction] = [
        .bold,
        .underline,
        .italic,
        .strikeThrough,
        .cancelFormat
    ]

    let textItems: [EditorToolbarAction] = [
        .unorderedList
    ]

    var allItems: [[EditorToolbarAction]] {
        [extras, textFormats, textItems]
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                ForEach(allItems, id: \.self) { items in
                    ForEach(items, id: \.self) { item in
                        Button(
                            action: {
                                item.action(
                                    textAttributes: textAttributes,
                                    isShowingLinkAlert: &isShowingLinkAlert,
                                    isShowingFileSelection: &isShowingFileSelection
                                )
                            }, label: {
                                item.icon.swiftUIImage
                                    .padding(IKPadding.medium)
                            }
                        )
                        .buttonStyle(MacosToolbarButtonStyle(isActive: item.isSelected(textAttributes: textAttributes)))
//                        .popoverToolbarHelp(title: item.accessibilityLabel)
                    }

                    if allItems.last != items {
                        Divider()
                            .padding(.vertical, value: .medium)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, IKPadding.composeViewHeaderHorizontal)

            IKDivider()
        }
    }
}

struct MacosToolbarButtonStyle: ButtonStyle {
    @State private var isHovered = false
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(isHovered ? MailResourcesAsset.hoverMenuBackground.swiftUIColor : .clear)
            .background(isActive ? MailResourcesAsset.hoverMenuBackground.swiftUIColor : .clear)
            .foregroundColor(isActive ? .primary : .secondary)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.25)) {
                    isHovered = hovering
                }
            }
    }
}

struct PopoverToolbarHelp: ViewModifier {
    @State private var isShowing = false
    let title: String

    func body(content: Content) -> some View {
        content
            .onHover { hover in
                isShowing = hover
            }
            .popover(isPresented: $isShowing, arrowEdge: .bottom) {
                ZStack {
                    MailResourcesAsset.onTagExternalColor.swiftUIColor
                        .scaleEffect(1.5)

                    Text(title)
                        .foregroundColor(.white)
                        .padding()
                }
            }
    }
}

public extension View {
    func popoverToolbarHelp(title: String) -> some View {
        modifier(PopoverToolbarHelp(title: title))
    }
}

#Preview {
    ComposeMessageMacosToolbarView(
        textAttributes: TextAttributes(),
        isShowingLinkAlert: .constant(false),
        isShowingFileSelection: .constant(false)
    )
}
