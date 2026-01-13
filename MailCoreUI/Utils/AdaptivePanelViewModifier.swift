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

import DesignSystem
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
            .sheet(item: Binding(get: {
                isCompactWindow ? item : nil
            }, set: { newValue in
                item = newValue
            })) { item in
                if #available(iOS 16.0, *) {
                    panelContent(item)
                        .modifier(SelfSizingPanelViewModifier(topPadding: IKPadding.large,
                                                              bottomPadding: IKPadding.medium))
                        .background(MailResourcesAsset.backgroundSecondaryColor.swiftUIColor)
                } else {
                    panelContent(item)
                        .modifier(SelfSizingPanelBackportViewModifier(topPadding: IKPadding.large,
                                                                      bottomPadding: IKPadding.medium))
                        .background(MailResourcesAsset.backgroundSecondaryColor.swiftUIColor)
                }
            }
            .popover(item:
                Binding(get: {
                    isCompactWindow ? nil : item
                }, set: { newValue in
                    item = newValue
                }),
                arrowEdge: popoverArrowEdge) { item in
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
