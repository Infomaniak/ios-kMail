/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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
import SwiftUI
import WrappingHStack

public struct BackportedFlowLayout<Collection: RandomAccessCollection, Content: View, ID: Hashable>: View {
    let elements: Collection
    let id: KeyPath<Collection.Element, ID>
    let verticalSpacing: CGFloat
    let horizontalSpacing: CGFloat

    let content: (Collection.Element) -> Content

    public init(
        _ elements: Collection,
        verticalSpacing: CGFloat,
        horizontalSpacing: CGFloat,
        @ViewBuilder content: @escaping (Collection.Element) -> Content
    ) where Collection.Element: Identifiable, ID == Collection.Element.ID {
        self.elements = elements
        id = \.id
        self.verticalSpacing = verticalSpacing
        self.horizontalSpacing = horizontalSpacing
        self.content = content
    }

    public init(
        _ elements: Collection,
        id: KeyPath<Collection.Element, ID>,
        verticalSpacing: CGFloat,
        horizontalSpacing: CGFloat,
        @ViewBuilder content: @escaping (Collection.Element) -> Content
    ) {
        self.elements = elements
        self.id = id
        self.verticalSpacing = verticalSpacing
        self.horizontalSpacing = horizontalSpacing
        self.content = content
    }

    public var body: some View {
        if #available(iOS 16.0, *) {
            FlowLayout(alignment: .leading, verticalSpacing: verticalSpacing, horizontalSpacing: horizontalSpacing) {
                ForEach(elements, id: id) { element in
                    content(element)
                }
            }
        } else {
            WrappingHStack(spacing: .constant(horizontalSpacing), lineSpacing: verticalSpacing) {
                ForEach(elements, id: id) { element in
                    content(element)
                }
            }
        }
    }
}
