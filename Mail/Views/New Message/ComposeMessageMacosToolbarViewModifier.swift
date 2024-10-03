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

import MailCore
import MailResources
import Popovers
import SwiftUI

struct PopoverToolbarHelp: ViewModifier {
    @State private var isShowing = false
    @State private var unBouncetimer: Timer?
    let title: String

    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                hoverHelp(isHovering: hovering)
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
                    PopoverReader { context in
                        popoverArrowBuilder(
                            arrowWidth: 12.0,
                            sourceFrame: context.attributes.sourceFrame(),
                            popoverFrame: context.frame
                        )
                        .fill(MailResourcesAsset.onTagExternalColor.swiftUIColor)
                    }
                }
            )
    }

    private func hoverHelp(isHovering: Bool) {
        guard isHovering else {
            unBouncetimer?.invalidate()
            isShowing = false
            return
        }
        unBouncetimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            unBouncetimer = nil
            isShowing = isHovering
        }
    }

    private func popoverArrowBuilder(arrowWidth: CGFloat, sourceFrame: CGRect, popoverFrame: CGRect) -> Path {
        Path {
            $0.move(to: CGPoint(
                x: sourceFrame.midX - arrowWidth,
                y: popoverFrame.maxY
            ))
            $0.addLine(to: CGPoint(
                x: sourceFrame.midX,
                y: sourceFrame.minY
            ))
            $0.addLine(to: CGPoint(
                x: sourceFrame.midX + arrowWidth,
                y: popoverFrame.maxY
            ))
            $0.closeSubpath()
        }
    }
}

struct KeyboardToolbarShortcut: ViewModifier {
    let keyboardShortcut: KeyboardShortcut?

    func body(content: Content) -> some View {
        if let keyboardShortcut, #available(macCatalystApplicationExtension 15.4, *) {
            content
                .keyboardShortcut(keyboardShortcut)
        } else {
            content
        }
    }
}

public extension View {
    func popoverToolbarHelp(title: String) -> some View {
        modifier(PopoverToolbarHelp(title: title))
    }

    func keyboardToolbarShortcut(_ shortcut: KeyboardShortcut?) -> some View {
        modifier(KeyboardToolbarShortcut(keyboardShortcut: shortcut))
    }
}
