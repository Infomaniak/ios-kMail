/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

import SwiftUI

public struct ViewWidthKey: PreferenceKey {
    public static var defaultValue: CGFloat = .zero

    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

public struct ViewHeightKey: PreferenceKey {
    public static var defaultValue: CGFloat = .zero

    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

public struct BottomSafeAreaKey: PreferenceKey {
    public static var defaultValue: CGFloat = .zero

    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

public struct BottomToolbarHeightKey: PreferenceKey {
    public static var defaultValue: CGFloat = .zero

    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

public struct ViewGeometry<K>: View where K: PreferenceKey {
    public let key: K.Type
    public let property: KeyPath<GeometryProxy, K.Value>

    public init(key: K.Type, property: KeyPath<GeometryProxy, K.Value>) {
        self.key = key
        self.property = property
    }

    public var body: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(key: key, value: proxy[keyPath: property])
        }
    }
}
