/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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
import MailResources
import SwiftUI

public extension View {
    func adaptivePanel<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        popoverArrowEdge: Edge = .top,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        return modifier(AdaptivePanelViewModifier(item: item, popoverArrowEdge: popoverArrowEdge, panelContent: content))
    }
}

struct AdaptivePanelViewModifier<Item: Identifiable, PanelContent: View>: ViewModifier {
    @Environment(\.isCompactWindow) private var isCompactWindow

    @Binding var item: Item?

    var popoverArrowEdge: Edge
    @ViewBuilder let panelContent: (Item) -> PanelContent

    func body(content: Content) -> some View {
        content
            .workaroundPopover(item: $item, arrowEdge: popoverArrowEdge) { item in
                if isCompactWindow {
                    if #available(iOS 16.0, *) {
                        panelContent(item).modifier(SelfSizingPanelViewModifier(bottomPadding: IKPadding.medium))
                    } else {
                        panelContent(item).modifier(SelfSizingPanelBackportViewModifier(bottomPadding: IKPadding.medium))
                    }
                } else {
                    ScrollView {
                        panelContent(item)
                    }
                    .padding(.vertical)
                    .frame(idealWidth: 400)
                    // DO NOT SUPPRESS the scaleEffect it's required for the contrast for macOS
                    .background(MailResourcesAsset.backgroundColor.swiftUIColor.scaleEffect(1.5))
                }
            }
    }
}

// MARK: - WorkaroundPopover

private extension View {
    func workaroundPopover<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        arrowEdge: Edge,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        modifier(WorkaroundPopover(item: item, arrowEdge: arrowEdge, panelContent: content))
    }
}

// FIXME: Remove this workaround when the Release Candidate of Xcode 16.2 is release
/// iOS 18.1 introduces an issue with the popover (135231043) fixed by iOS 18.2 (the bug is also visible on iOS 18.0)
///
/// In this specific version of iOS, the `popover` type signature has been changed. The `arrowEdge: Edge?`
/// parameter is no longer optional with the default value of nil. The default value is now `Edge.top`
/// which causes the popover to be hidden in some cases.
///
/// Therefore for iOS 18.1 and later versions (while we build with Xcode 16.1) we have to provide a value for `arrowEdge`.
private struct WorkaroundPopover<Item: Identifiable, PanelContent: View>: ViewModifier {
    @Binding var item: Item?

    let arrowEdge: Edge
    @ViewBuilder let panelContent: (Item) -> PanelContent

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .popover(item: $item, arrowEdge: arrowEdge) { item in
                    panelContent(item)
                }
        } else {
            content
                .popover(item: $item) { item in
                    panelContent(item)
                }
        }
    }
}
