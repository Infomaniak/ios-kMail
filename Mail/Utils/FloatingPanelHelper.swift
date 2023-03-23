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
import FloatingPanel
import MailResources
import SwiftUI

class AdaptiveDriveFloatingPanelController: FloatingPanelController {
    private var contentSizeObservation: NSKeyValueObservation?
    private let maxPanelWidth = 800.0
    var halfOpening = false

    deinit {
        contentSizeObservation?.invalidate()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateMargins()
        updateLayout(size: size)
    }

    private func updateMargins() {
        if view.frame.size.width > maxPanelWidth {
            let insetWidth = view.frame.width - maxPanelWidth
            surfaceView.containerMargins = UIEdgeInsets(top: 0, left: insetWidth / 2, bottom: 0, right: insetWidth / 2)
        } else {
            surfaceView.containerMargins = .zero
        }
    }

    func updateLayout(size: CGSize) {
        guard let trackingScrollView = trackingScrollView else { return }
        let fullHeight = min(
            trackingScrollView.contentSize.height + surfaceView.contentPadding.top + surfaceView.contentPadding.bottom,
            size.height - 96
        )
        let layout = AdaptiveFloatingPanelLayout(
            height: fullHeight,
            halfOpening: halfOpening && fullHeight > size.height / 2
        )
        self.layout = layout
        invalidateLayout()
    }

    func trackAndObserve(scrollView: UIScrollView) {
        contentSizeObservation?.invalidate()
        contentSizeObservation = scrollView.observe(\.contentSize, options: [.new, .old]) { [weak self] _, observedChanges in
            // Do not update layout if the new value is the same as the old one (to fix a bug with collectionView)
            guard observedChanges.newValue != observedChanges.oldValue,
                  let window = self?.view.window else { return }
            self?.updateLayout(size: window.bounds.size)
        }
        track(scrollView: scrollView)
        if let window = view.window {
            updateMargins()
            updateLayout(size: window.bounds.size)
        }
    }
}

class AdaptiveFloatingPanelLayout: FloatingPanelLayout {
    let position: FloatingPanelPosition = .bottom
    let anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring]
    let initialState: FloatingPanelState

    init(height: CGFloat, halfOpening: Bool) {
        initialState = .half
        if halfOpening {
            anchors = [
                .half: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .safeArea),
                .full: FloatingPanelLayoutAnchor(absoluteInset: height, edge: .bottom, referenceGuide: .safeArea)
            ]
        } else {
            anchors = [
                .half: FloatingPanelLayoutAnchor(absoluteInset: height, edge: .bottom, referenceGuide: .safeArea)
            ]
        }
    }

    func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
        return 0.2
    }
}

class DisplayedFloatingPanelState<State>: ObservableObject, FloatingPanelControllerDelegate {
    @Published var isOpen = false
    @Published private(set) var state: State?

    private let floatingPanel: AdaptiveDriveFloatingPanelController

    init() {
        floatingPanel = AdaptiveDriveFloatingPanelController()
        let appearance = SurfaceAppearance()
        appearance.cornerRadius = 20
        appearance.backgroundColor = MailResourcesAsset.backgroundSecondaryColor.color
        floatingPanel.delegate = self
        floatingPanel.surfaceView.appearance = appearance
        floatingPanel.surfaceView.grabberHandlePadding = 16
        floatingPanel.surfaceView.grabberHandleSize = CGSize(width: 45, height: 5)
        floatingPanel.surfaceView.grabberHandle.barColor = MailResourcesAsset.elementsColor.color
        floatingPanel.surfaceView.contentPadding = UIEdgeInsets(top: 32, left: 0, bottom: 16, right: 0)
        floatingPanel.backdropView.dismissalTapGestureRecognizer.isEnabled = true
        floatingPanel.isRemovalInteractionEnabled = true
    }

    func createPanelContent<Content: View>(content: Content, halfOpening: Bool) {
        floatingPanel.halfOpening = halfOpening
        let content = content.introspectScrollView { [weak self] scrollView in
            self?.floatingPanel.trackAndObserve(scrollView: scrollView)
        }
        let viewController = UIHostingController(rootView: content)
        viewController.view.backgroundColor = nil
        floatingPanel.set(contentViewController: viewController)
    }

    func open(state: State) {
        if let rootViewController = FloatingPanelHelper.shared.rootViewController {
            rootViewController.present(floatingPanel, animated: true)
            self.state = state
            isOpen = true
        }
    }

    func close() {
        state = nil
        isOpen = false
        floatingPanel.dismiss(animated: true)
    }

    func floatingPanelDidRemove(_ fpc: FloatingPanelController) {
        state = nil
        isOpen = false
    }
}

class FloatingPanelHelper: FloatingPanelControllerDelegate {
    static let shared = FloatingPanelHelper()

    private let sharedFloatingPanel = FloatingPanelController()
    private(set) var rootViewController: UIViewController?
    private init() {
        // Protected constructor for singleton
    }

    func attachToViewController(_ viewController: UIViewController) {
        rootViewController = viewController
    }
}

extension View {
    func floatingPanel<State, Content: View>(state: DisplayedFloatingPanelState<State>,
                                             halfOpening: Bool = false,
                                             @ViewBuilder content: () -> Content) -> some View {
        state.createPanelContent(content: ScrollView { content() }.defaultAppStorage(.shared),
                                 halfOpening: halfOpening)
        return self
    }
}
