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

import SwiftUI

struct TitlePosition: Equatable {
    let isFullyBellowNavigationBar: Bool
    let offsetProgress: Double

    init() {
        isFullyBellowNavigationBar = false
        offsetProgress = 0
    }

    init(proxy: GeometryProxy) {
        let globalFrame = proxy.frame(in: .global)
        let localFrame = proxy.frame(in: .named("scrollView"))

        isFullyBellowNavigationBar = localFrame.maxY <= 0

        let initialYPosition = globalFrame.minY - localFrame.minY
        offsetProgress = max(0, min(1, (initialYPosition - globalFrame.minY) / initialYPosition))
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue = TitlePosition()

    static func reduce(value: inout TitlePosition, nextValue: () -> TitlePosition) {
        // No need to implement it
    }
}

extension View {
    func threadTitle() -> some View {
        modifier(ThreadTitleModifier())
    }
}

struct ThreadTitleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textStyle(.header2)
            .multilineTextAlignment(.leading)
            .lineSpacing(8)
            .padding(.top, value: .mini)
            .overlay {
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: TitlePosition(proxy: proxy))
                }
            }
    }
}
