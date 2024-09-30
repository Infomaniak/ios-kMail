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

import MailResources
import SwiftUI

public extension View {
    func adaptivePanel<Item: Identifiable, Content: View>(item: Binding<Item?>,
                                                          @ViewBuilder content: @escaping (Item) -> Content) -> some View {
        return modifier(AdaptivePanelViewModifier(item: item, panelContent: content))
    }
}

public struct AdaptivePanelViewModifier<Item: Identifiable, PanelContent: View>: ViewModifier {
    @Environment(\.isCompactWindow) private var isCompactWindow

    @Binding var item: Item?
    @ViewBuilder let panelContent: (Item) -> PanelContent

    public init(item: Binding<Item?>, panelContent: @escaping (Item) -> PanelContent) {
        _item = item
        self.panelContent = panelContent
    }

    public func body(content: Content) -> some View {
        content
            .popover(item: $item) { item in
                if isCompactWindow {
                    if #available(iOS 16.0, *) {
                        panelContent(item).modifier(SelfSizingPanelViewModifier())
                    } else {
                        panelContent(item).modifier(SelfSizingPanelBackportViewModifier())
                    }
                } else {
                    ScrollView {
                        panelContent(item)
                    }
                    .padding(.vertical)
                    .frame(idealWidth: 400)
                    //DO NOT SUPPRESS the scaleEffect, it's required§ for the ActionsViews to be white
                    .background(MailResourcesAsset.backgroundColor.swiftUIColor.scaleEffect(1.5))
                }
            }
    }
}
