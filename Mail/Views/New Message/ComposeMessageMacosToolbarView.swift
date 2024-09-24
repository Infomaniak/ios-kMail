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

    @State private var activePopover: String? = nil

    let extras: [EditorToolbarItem] = [
        .attachment,
        .link
    ]

    let textFormats: [EditorToolbarItem] = [
        .bold,
        .underline,
        .italic,
        .strikeThrough,
        .cancel
    ]

    let textItems: [EditorToolbarItem] = [
        .unorderedList
    ]

    var allItems: [[EditorToolbarItem]] {
        [
            extras,
            textFormats,
            textItems
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                ForEach(allItems, id: \.self) { items in
                    ForEach(items, id: \.self) { item in
                        Button(
                            action: {
                                toolbarItemAction(item)
                            }, label: {
                                item.icon
                                    .padding(IKPadding.medium)
                            }
                        )
                        .onHover { hover in
                            activePopover = hover ? item.name : nil
                        }
                        .buttonStyle(MacosToolbarButtonStyle(isActive: item.isActive(textAttributes)))
                        .popover(present: Binding<Bool>(
                            get: { activePopover == item.name },
                            set: { if !$0 { activePopover = nil } }
                        ),
                        attributes: {
                            $0.sourceFrameInset.top = -8
                            $0.position = .absolute(originAnchor: .top, popoverAnchor: .bottom)
                        }) {
                            Templates.Container(
                                backgroundColor: MailResourcesAsset.onTagExternalColor.swiftUIColor
                            ) {
                                Text(item.name)
                                    .foregroundColor(.white)
                            }
                        }
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

    private func toolbarItemAction(_ item: EditorToolbarItem) {
        switch item {
        case .bold:
            textAttributes.bold()
        case .underline:
            textAttributes.underline()
        case .italic:
            textAttributes.italic()
        case .strikeThrough:
            textAttributes.strikethrough()
        case .cancel:
            textAttributes.removeFormat()
        case .unorderedList:
            textAttributes.unorderedList()
        case .link:
            guard !textAttributes.hasLink else {
                return textAttributes.unlink()
            }
            isShowingLinkAlert = true
        case .attachment:
            isShowingFileSelection = true
        }
    }
}

enum EditorToolbarItem {
    case attachment
    case link
    case bold
    case underline
    case italic
    case strikeThrough
    case cancel
    case unorderedList

    var icon: Image {
        switch self {
        case .attachment:
            return MailResourcesAsset.newMailToolbarAttachment.swiftUIImage
        case .link:
            return MailResourcesAsset.newMailToolbarHyperlink.swiftUIImage
        case .bold:
            return MailResourcesAsset.newMailToolbarBold.swiftUIImage
        case .underline:
            return MailResourcesAsset.newMailToolbarUnderline.swiftUIImage
        case .italic:
            return MailResourcesAsset.newMailToolbarItalic.swiftUIImage
        case .strikeThrough:
            return MailResourcesAsset.newMailToolbarStrike.swiftUIImage
        case .cancel:
            return MailResourcesAsset.newMailToolbarCancelFormat.swiftUIImage
        case .unorderedList:
            return MailResourcesAsset.newMailToolbarList.swiftUIImage
        }
    }

    var name: String {
        switch self {
        case .attachment:
            return MailResourcesStrings.Localizable.attachmentActionTitle
        case .link:
            return MailResourcesStrings.Localizable.buttonHyperlink
        case .bold:
            return MailResourcesStrings.Localizable.buttonBold
        case .underline:
            return MailResourcesStrings.Localizable.buttonUnderline
        case .italic:
            return MailResourcesStrings.Localizable.buttonItalic
        case .strikeThrough:
            return MailResourcesStrings.Localizable.buttonStrikeThrough
        case .cancel:
            return MailResourcesStrings.Localizable.buttonCancelFormatting
        case .unorderedList:
            return MailResourcesStrings.Localizable.buttonBulletPoint
        }
    }

    func isActive(_ textAttributes: TextAttributes) -> Bool {
        switch self {
        case .bold:
            textAttributes.hasBold
        case .underline:
            textAttributes.hasUnderline
        case .italic:
            textAttributes.hasItalic
        case .strikeThrough:
            textAttributes.hasStrikethrough
        case .unorderedList:
            textAttributes.hasUnorderedList
        case .attachment, .link, .cancel:
            false
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

#Preview {
    ComposeMessageMacosToolbarView(
        textAttributes: TextAttributes(),
        isShowingLinkAlert: .constant(false),
        isShowingFileSelection: .constant(false)
    )
}
