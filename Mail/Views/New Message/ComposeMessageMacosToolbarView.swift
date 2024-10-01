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

    private let extras: [EditorToolbarAction] = [
        .attachment,
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
        [extras, textFormats, textItems]
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: IKPadding.extraSmall) {
                ForEach(allItems, id: \.self) { items in
                    ForEach(items, id: \.self) { item in
                        Button {
                            item.action(
                                textAttributes: textAttributes,
                                isShowingLinkAlert: &isShowingLinkAlert,
                                isShowingFileSelection: &isShowingFileSelection
                            )
                        } label: {
                            item.icon.swiftUIImage
                                .resizable()
                                .frame(width: 16, height: 16)
                                .padding(value: .small)
                        }
                        .buttonStyle(MacosToolbarButtonStyle(isActive: item.isSelected(textAttributes: textAttributes)))
                        .popoverToolbarHelp(title: item.accessibilityLabel)
                    }

                    if allItems.last != items {
                        Divider()
                            .padding(.vertical, value: .medium)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(isHovered ? MailResourcesAsset.hoverMenuBackground.swiftUIColor : .clear)
            .background(isActive ? accentColor.secondary.swiftUIColor : .clear)
            .foregroundColor(.primary)
            .cornerRadius(2)
            .onHover { hovering in
                withAnimation {
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
            .onHover { hovering in
                isShowing = hovering
            }
            .popover(
                present: $isShowing,
                attributes: {
                    $0.sourceFrameInset.top = -8
                    $0.position = .absolute(
                        originAnchor: .top,
                        popoverAnchor: .bottom
                    )
                    $0.screenEdgePadding = .zero
                },
                view: {
                    Text(title)
                        .padding(value: .medium)
                        .background(MailResourcesAsset.onTagExternalColor.swiftUIColor)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .foregroundColor(MailTextStyle.bodyPopover.color)
                }, background: {
                    let triangleWidth = 12.0
                    PopoverReader { context in
                        Path {
                            $0.move(to: CGPoint(
                                x: context.attributes.sourceFrame().midX - triangleWidth,
                                y: context.frame.maxY
                            ))
                            $0.addLine(to: CGPoint(
                                x: context.attributes.sourceFrame().midX,
                                y: context.attributes.sourceFrame().minY
                            ))
                            $0.addLine(to: CGPoint(
                                x: context.attributes.sourceFrame().midX + triangleWidth,
                                y: context.frame.maxY
                            ))
                            $0.closeSubpath()
                        }
                        .fill(MailResourcesAsset.onTagExternalColor.swiftUIColor)
                    }
                }
            )
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
