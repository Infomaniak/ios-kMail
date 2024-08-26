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

import Combine
import MailCore
import SwiftUI

public final class ScrollObserver: ObservableObject {
    public enum ScrollDirection {
        case none, top, bottom
    }

    private static let threshold: ClosedRange<CGFloat> = -80 ... 80

    @Published public var scrollDirection = ScrollDirection.none

    public var shouldObserve = true

    private var subscriber: Cancellable?
    private var lastContentOffset = CGFloat.zero

    private weak var scrollView: UIScrollView?

    public init() {}

    public func observeValue(scrollView: UIScrollView) {
        guard subscriber == nil else { return }

        subscriber = scrollView.publisher(for: \.contentOffset).sink { newValue in
            self.scrollViewDidScroll(offset: newValue.y)
        }
        self.scrollView = scrollView
    }

    private func scrollViewDidScroll(offset: CGFloat) {
        guard shouldObserve else { return }

        // Do not take into account the top bounce
        guard offset >= 0 else { return }

        // Do not take into account the bottom bounce
        if let scrollView {
            let offsetBottom = offset + scrollView.visibleSize.height
            let contentHeight = scrollView.contentSize.height + scrollView.safeAreaInsets.bottom

            if offsetBottom > contentHeight {
                return
            }
        }

        let difference = lastContentOffset - offset
        guard !Self.threshold.contains(difference) else { return }
        let newDirection: ScrollDirection = difference > 0 ? .top : .bottom
        updateScrollDirection(offset: offset, direction: newDirection)
    }

    private func updateScrollDirection(offset: CGFloat, direction: ScrollDirection) {
        lastContentOffset = offset

        guard scrollDirection != direction else { return }
        Task { @MainActor [direction] in
            withAnimation {
                scrollDirection = direction
            }
        }
    }
}

public extension View {
    func observeScroll(with scrollObserver: ScrollObserver) -> some View {
        modifier(ScrollObserverModifier(scrollObserver: scrollObserver))
    }
}

public struct ScrollObserverModifier: ViewModifier {
    let scrollObserver: ScrollObserver

    public init(scrollObserver: ScrollObserver) {
        self.scrollObserver = scrollObserver
    }

    public func body(content: Content) -> some View {
        content
            .introspect(.list, on: .iOS(.v15)) { scrollObserver.observeValue(scrollView: $0) }
            .introspect(.list, on: .iOS(.v16, .v17)) { scrollObserver.observeValue(scrollView: $0) }
    }
}
