/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import SwiftUI

extension View {
    func adaptivePanel<Item: Identifiable, Content: View>(item: Binding<Item?>,
                                                          @ViewBuilder content: @escaping (Item) -> Content) -> some View {
        return modifier(AdaptivePanelViewItemModifier(item: item, panelContent: content))
    }

    func adaptivePanel<Content: View>(isPresented: Binding<Bool>,
                                      @ViewBuilder content: @escaping () ->
                                          Content) -> some View {
        return modifier(AdaptivePanelViewIsPresentedModifier(isPresented: isPresented, panelContent: content))
    }
}

struct AdaptivePanelViewItemModifier<Item: Identifiable, PanelContent: View>: ViewModifier {
    @Binding var item: Item?
    @ViewBuilder var panelContent: (Item) -> PanelContent
    func body(content: Content) -> some View {
        content
            .popover(item: $item) { item in
                AdaptativeView {
                    panelContent(item)
                }
            }
    }
}

struct AdaptivePanelViewIsPresentedModifier<PanelContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    @ViewBuilder var panelContent: PanelContent

    func body(content: Content) -> some View {
        content
            .popover(isPresented: $isPresented) {
                AdaptativeView {
                    panelContent
                }
            }
    }
}

struct AdaptativeView<Content: View>: View {
    @Environment(\.isCompactWindow) private var isCompactWindow
    @ViewBuilder var panelContent: Content

    var body: some View {
        if isCompactWindow {
            if #available(iOS 16.0, *) {
                panelContent.modifier(SelfSizingPanelViewModifier())
            } else {
                panelContent.modifier(SelfSizingPanelBackportViewModifier())
            }
        } else {
            panelContent
                .padding()
                .frame(idealWidth: 400)
        }
    }
}
