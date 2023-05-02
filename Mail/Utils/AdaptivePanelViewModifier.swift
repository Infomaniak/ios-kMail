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
        return modifier(AdaptivePanelViewModifier(item: item, panelContent: content))
    }
}

struct AdaptivePanelViewModifier<Item: Identifiable, PanelContent: View>: ViewModifier {
    @Environment(\.isCompactWindow) private var isCompactWindow

    @Binding var item: Item?
    @ViewBuilder var panelContent: (Item) -> PanelContent

    func body(content: Content) -> some View {
        if isCompactWindow {
            content.floatingPanel(item: $item) { item in
                panelContent(item)
            }
        } else {
            content.popover(item: $item) { item in
                panelContent(item)
                    .padding()
                    .frame(idealWidth: 400)
            }
        }
    }
}

extension View {
    func adaptiveActions(item: Binding<ActionsTarget?>) -> some View {
        return modifier(AdaptiveActionsViewModifier(item: item))
    }
}

struct AdaptiveActionsViewModifier: ViewModifier {
    @Environment(\.isCompactWindow) private var isCompactWindow

    @Binding var item: ActionsTarget?

    func body(content: Content) -> some View {
        if isCompactWindow {
            content.actionsPanel(actionsTarget: $item)
        } else {
            content.actionsPopOver(actionsTarget: $item)
        }
    }
}
