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
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI
import WebKit

final class WebViewController: UIViewController {
    let messageUid: String
    let openURL: OpenURLAction
    let webView: WKWebView
    let isEmailContrastEnabled: Bool
    let onWebKitProcessTerminated: (() -> Void)?

    private let documentReady: AnyPublisher<Void, Never>
    private var documentReadySubscriber: AnyCancellable?

    private let normalizationRequest = PassthroughSubject<Void, Never>()
    private var normalizationSubscriber: AnyCancellable?
    private var normalizeTask: Task<Void, Never>?

    private var isDocumentReady = false
    private var shouldRemoveAllProperties = false
    private var lastNormalizedWidth: CGFloat?

    private var mentionMenuAnchor: UIButton?
    private var lastPresentedMentionID: UUID?

    #if targetEnvironment(macCatalyst)
    private static let zoomScaleTolerance = 0.01
    private static let horizontalOverflowThreshold = 4.0

    private var scrollLockObservations = [NSKeyValueObservation]()
    #endif

    private var isSceneActive: Bool {
        guard let windowScene = view.window?.windowScene else { return true }
        return windowScene.activationState == .foregroundActive
    }

    init(
        messageUid: String,
        openURL: OpenURLAction,
        webView: WKWebView,
        documentReady: AnyPublisher<Void, Never>,
        isEmailContrastEnabled: Bool,
        onWebKitProcessTerminated: (() -> Void)?
    ) {
        self.messageUid = messageUid
        self.openURL = openURL
        self.webView = webView
        self.documentReady = documentReady
        self.isEmailContrastEnabled = isEmailContrastEnabled
        self.onWebKitProcessTerminated = onWebKitProcessTerminated

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()

        // In some cases the UIWebView was still owned by an other UIViewController
        webView.removeFromSuperview()
        view.addSubview(webView)

        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.heightAnchor.constraint(equalTo: view.heightAnchor),
            webView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])

        setUpWebView(webView)

        normalizationSubscriber = normalizationRequest
            .merge(with: NotificationCenter.default.publisher(for: UIScene.didActivateNotification).map { _ in })
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { [weak self] in
                self?.normalizeIfNeeded()
            }

        documentReadySubscriber = documentReady
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.handleContentLoaded()
            }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle,
              isDocumentReady else {
            return
        }

        Task { @MainActor in
            try? await applyEmailContrastIfNeeded()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        normalizationRequest.send()

        #if targetEnvironment(macCatalyst)
        updateScrollLock(webView.scrollView)
        #endif
    }

    private func setUpWebView(_ webView: WKWebView) {
        webView.navigationDelegate = self
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = true
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.alwaysBounceHorizontal = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        #if targetEnvironment(macCatalyst)
        setUpScrollLock(webView.scrollView)
        #endif

        #if DEBUG
        webView.isInspectable = true
        #endif
    }

    private func handleContentLoaded() {
        isDocumentReady = true
        shouldRemoveAllProperties = true
        normalizeIfNeeded()
    }

    private func normalizeIfNeeded() {
        let width = view.bounds.width
        guard isDocumentReady,
              isSceneActive,
              width > 0,
              width != lastNormalizedWidth || shouldRemoveAllProperties else {
            return
        }

        lastNormalizedWidth = width
        let shouldRemoveAllProperties = shouldRemoveAllProperties
        self.shouldRemoveAllProperties = false

        #if targetEnvironment(macCatalyst)
        let contentSize: CGFloat = 0
        let scaleCompensation = 100.0 / 77.0
        #else
        let contentSize = UIFont.preferredFont(forTextStyle: .body).pointSize
        let scaleCompensation: CGFloat = 0
        #endif

        normalizeTask?.cancel()
        normalizeTask = Task { [weak self, webView, messageUid] in
            _ = try? await webView.evaluateJavaScript(.normalizeMessage(
                width: width,
                messageUid: messageUid,
                contentSize: contentSize,
                scaleCompensation: scaleCompensation,
                shouldRemoveAllProperties: shouldRemoveAllProperties
            ))
            if shouldRemoveAllProperties {
                try? await self?.applyEmailContrastIfNeeded()
            }
        }
    }

    private func applyEmailContrastIfNeeded() async throws {
        guard isEmailContrastEnabled else { return }
        try await webView.evaluateJavaScript(.applyEmailDarkModeContrast)
    }

    func presentMentionMenuIfNeeded(_ content: MentionMenuContent) {
        guard content.id != lastPresentedMentionID else { return }
        lastPresentedMentionID = content.id
        presentMentionMenu(content)
    }

    func resetMentionMenuState() {
        lastPresentedMentionID = nil
    }

    func presentMentionMenu(_ content: MentionMenuContent) {
        var anchorRect = view.convert(content.rect, from: webView)
        anchorRect.origin.y += anchorRect.height + 4
        anchorRect.size.height = 1

        mentionMenuAnchor?.removeFromSuperview()

        let anchor = UIButton(frame: anchorRect)
        anchor.alpha = 0
        view.addSubview(anchor)
        mentionMenuAnchor = anchor

        let uiActions = content.actions.map { action -> UIAction in
            var attributes: UIMenuElement.Attributes = []
            if action.isDestructive { attributes.insert(.destructive) }
            if action.isDisabled { attributes.insert(.disabled) }
            return UIAction(title: action.title, image: action.image, attributes: attributes) { _ in
                action.handler()
            }
        }

        let headerAction = UIAction(
            title: content.title,
            subtitle: content.subtitle,
            image: content.image,
            attributes: .disabled
        ) { _ in }

        let menuChildren: [UIMenuElement] = [
            UIMenu(options: .displayInline, children: [headerAction]),
            UIMenu(options: .displayInline, children: uiActions)
        ]

        anchor.menu = UIMenu(title: "", children: menuChildren)
        anchor.showsMenuAsPrimaryAction = true

        if #available(iOS 17.4, *) {
            anchor.performPrimaryAction()
        } else {
            presentMentionActionSheet(content, sourceRect: anchorRect)
        }
    }

    private func presentMentionActionSheet(_ content: MentionMenuContent, sourceRect: CGRect) {
        let message = [content.title, content.subtitle].compactMap { $0 }.joined(separator: "\n")
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)

        for action in content.actions {
            let alertAction = UIAlertAction(title: action.title, style: action.isDestructive ? .destructive : .default) { _ in
                action.handler()
            }
            alertAction.isEnabled = !action.isDisabled
            alert.addAction(alertAction)
        }
        alert.addAction(UIAlertAction(title: MailResourcesStrings.Localizable.buttonCancel, style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = sourceRect
        }

        present(alert, animated: true)
    }
}

#if targetEnvironment(macCatalyst)
extension WebViewController {
    func setUpScrollLock(_ scrollView: UIScrollView) {
        scrollLockObservations = [
            scrollView.observe(\.zoomScale) { [weak self] scrollView, _ in
                self?.updateScrollLock(scrollView)
            },
            scrollView.observe(\.contentSize) { [weak self] scrollView, _ in
                self?.updateScrollLock(scrollView)
            }
        ]

        updateScrollLock(scrollView)
    }

    func updateScrollLock(_ scrollView: UIScrollView) {
        let isZoomedIn = scrollView.zoomScale > 1 + Self.zoomScaleTolerance
        let horizontalOverflow = scrollView.contentSize.width - scrollView.bounds.width
        let hasHorizontalOverflow = horizontalOverflow > Self.horizontalOverflowThreshold

        scrollView.panGestureRecognizer.isEnabled = isZoomedIn || hasHorizontalOverflow

        if !isZoomedIn && scrollView.contentOffset.y != 0 {
            scrollView.contentOffset.y = 0
        }
    }
}
#endif

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        handleContentLoaded()
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let url = navigationAction.request.url, Constants.isMailTo(url) {
            decisionHandler(.cancel)
            openURL(url)
            return
        }

        if navigationAction.navigationType == .linkActivated {
            if let url = navigationAction.request.url {
                decisionHandler(.cancel)
                openURL(url)
            }
        } else {
            decisionHandler(.allow)
        }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        onWebKitProcessTerminated?()
    }
}

struct MentionMenuAction {
    let title: String
    let image: UIImage?
    var isDestructive = false
    var isDisabled = false
    let handler: () -> Void
}

struct MentionMenuContent {
    let id = UUID()
    let title: String
    let subtitle: String?
    let image: UIImage?
    let rect: CGRect
    let actions: [MentionMenuAction]
}

struct WebView: UIViewControllerRepresentable {
    @Environment(\.openURL) private var openURL

    let webView: WKWebView
    let messageUid: String
    let documentReady: AnyPublisher<Void, Never>
    let isEmailContrastEnabled: Bool

    @Binding var mentionMenuContent: MentionMenuContent?

    var onWebKitProcessTerminated: (() -> Void)?

    func makeUIViewController(context: Context) -> WebViewController {
        return WebViewController(
            messageUid: messageUid,
            openURL: openURL,
            webView: webView,
            documentReady: documentReady,
            isEmailContrastEnabled: isEmailContrastEnabled,
            onWebKitProcessTerminated: onWebKitProcessTerminated
        )
    }

    func updateUIViewController(_ uiViewController: WebViewController, context: Context) {
        guard let mentionMenuContent else {
            uiViewController.resetMentionMenuState()
            return
        }

        uiViewController.presentMentionMenuIfNeeded(mentionMenuContent)
        Task { @MainActor in
            self.mentionMenuContent = nil
        }
    }
}
