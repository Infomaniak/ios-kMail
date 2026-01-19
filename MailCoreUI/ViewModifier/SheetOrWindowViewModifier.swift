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

import InfomaniakCore
import InfomaniakDI
import SwiftUI

public extension View {
    func sheet<Item, Content>(
        item: Binding<Item?>,
        desktopIdentifier: String,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View where Item: Identifiable & Codable & Hashable, Content: View {
        return modifier(IdentifiableSheetOrDesktopWindowViewModifier(
            item: item,
            desktopWindowIdentifier: desktopIdentifier,
            sheetContent: content
        ))
    }
}

public struct IdentifiableSheetOrDesktopWindowViewModifier<Item: Identifiable & Codable & Hashable, SheetContent: View>:
    ViewModifier {
    @InjectService private var platformDetector: PlatformDetectable

    @Environment(\.openWindow) private var openWindow

    @Binding var item: Item?
    let desktopWindowIdentifier: String
    @ViewBuilder let sheetContent: (Item) -> SheetContent

    public func body(content: Content) -> some View {
        if platformDetector.isMac {
            content.onChange(of: item?.id) { _ in
                guard let item else { return }
                openWindow(id: desktopWindowIdentifier, value: item)
                self.item = nil
            }
        } else {
            content.sheet(item: $item) { item in
                sheetContent(item)
            }
        }
    }
}
