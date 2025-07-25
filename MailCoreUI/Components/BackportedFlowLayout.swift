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

public struct BackportedFlowLayout<Content: View>: View {
    let verticalSpacing: CGFloat
    let horizontalSpacing: CGFloat
    @ViewBuilder let content: () -> Content

    public init(verticalSpacing: CGFloat, horizontalSpacing: CGFloat, @ViewBuilder content: @escaping () -> Content) {
        self.verticalSpacing = verticalSpacing
        self.horizontalSpacing = horizontalSpacing
        self.content = content
    }

    public init<Data, RowContent>(
        _ data: Data,
        verticalSpacing: CGFloat,
        horizontalSpacing: CGFloat,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent
    ) where Content == ForEach<Data, Data.Element.ID, RowContent>, Data: RandomAccessCollection, RowContent: View,
        Data.Element: Identifiable {
        self.verticalSpacing = verticalSpacing
        self.horizontalSpacing = horizontalSpacing

        content = {
            ForEach(data) { element in
                rowContent(element)
            }
        }
    }

    public init<Data, ID, RowContent>(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        verticalSpacing: CGFloat,
        horizontalSpacing: CGFloat,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent
    ) where Content == ForEach<Data, ID, RowContent>, Data: RandomAccessCollection, ID: Hashable, RowContent: View {
        self.verticalSpacing = verticalSpacing
        self.horizontalSpacing = horizontalSpacing

        content = {
            ForEach(data, id: id) { element in
                rowContent(element)
            }
        }
    }

    public var body: some View {
        if #available(iOS 16.0, *) {
            FlowLayout(alignment: .leading, verticalSpacing: verticalSpacing, horizontalSpacing: horizontalSpacing) {
                content()
            }
        } else {
            WrappingHStack(spacing: .constant(horizontalSpacing), lineSpacing: verticalSpacing) {
                content()
            }
        }
    }
}
