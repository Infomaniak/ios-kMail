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

import Combine
import Foundation
import SwiftUI

public final class ScrollObserver: ObservableObject {
    enum ScrollDirection {
        case none, top, bottom
    }

    public var shouldObserve = true

    @Published var scrollDirection = ScrollDirection.none

    private var cancellable: Cancellable?
    private var lastContentOffset = CGFloat.zero

    public func observeValue(scrollView: UIScrollView) {
        guard cancellable == nil else { return }
        cancellable = scrollView.publisher(for: \.contentOffset).sink { newValue in
            self.updateScrollViewPosition(newOffset: newValue.y)
        }
    }

    private func updateScrollViewPosition(newOffset: CGFloat) {
        guard shouldObserve else { return }

        let newDirection: ScrollDirection
        defer {
            lastContentOffset = newOffset
            if scrollDirection != newDirection {
                print("New Direction ->", newDirection, lastContentOffset, newOffset)
                Task { @MainActor in
                    withAnimation {
                        scrollDirection = newDirection
                    }
                }
            }
        }

        guard newOffset >= 0 else {
            newDirection = .none
            return
        }

        if newOffset == lastContentOffset {
            newDirection = .none
        } else {
            newDirection = newOffset > lastContentOffset ? .bottom : .top
        }
    }
}

extension View {
    func observeScroll(with scrollObserver: ScrollObserver) -> some View {
        modifier(ScrollObserverModifier(scrollObserver: scrollObserver))
    }
}

struct ScrollObserverModifier: ViewModifier {
    let scrollObserver: ScrollObserver

    func body(content: Content) -> some View {
        content
            .introspect(.list, on: .iOS(.v15)) { scrollObserver.observeValue(scrollView: $0) }
            .introspect(.list, on: .iOS(.v16, .v17)) { scrollObserver.observeValue(scrollView: $0) }
    }
}
