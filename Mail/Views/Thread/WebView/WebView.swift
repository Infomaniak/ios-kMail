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
import Sentry
import SwiftUI
import WebKit

final class WebViewController: UIViewController {
    let messageUid: String
    let openURL: OpenURLAction
    let webView: WKWebView
    let onWebKitProcessTerminated: (() -> Void)?

    private let widthSubject = PassthroughSubject<Double, Never>()
    private var widthSubscriber: AnyCancellable?

    private var hasFinishedLoading = false

    private var mentionMenuAnchor: UIButton?
    private var lastPresentedMentionID: UUID?

    init(messageUid: String, openURL: OpenURLAction, webView: WKWebView, onWebKitProcessTerminated: (() -> Void)?) {
        self.messageUid = messageUid
        self.openURL = openURL
        self.webView = webView
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

        widthSubscriber = widthSubject
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { [weak self] newWidth in
                Task {
                    try await self?.normalizeMessageWidth(webViewWidth: CGFloat(newWidth), fromWidthSubscriber: true)
                }
            }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        widthSubject.send(size.width)
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

        #if DEBUG
        webView.isInspectable = true
        #endif
    }

    private func normalizeMessageWidth(webViewWidth width: CGFloat, fromWidthSubscriber: Bool = false) async throws {
        guard hasFinishedLoading else { return }
        #if targetEnvironment(macCatalyst)
        let scaleCompensation = 100.0 / 77.0
        try await webView.evaluateJavaScript(.setScaleCompensation(scaleCompensation))
        try await webView.evaluateJavaScript(.normalizeMessageWidth(width, messageUid))
        #else
        let font = UIFont.preferredFont(forTextStyle: .body)
        try await webView.evaluateJavaScript(.setContentSize(font.pointSize))
        try await webView.evaluateJavaScript(.normalizeMessageWidth(width, messageUid))
        #endif

        // Sometimes we have a width equals to zero, we want to understand what happens in this case
        if width <= 0 {
            reportNullSize(givenWidth: width, fromWidthSubscriber: fromWidthSubscriber)
        }
    }

    private func reportNullSize(givenWidth: CGFloat, fromWidthSubscriber: Bool) {
        SentrySDK.capture(message: "Munge Mail: Width is equal to 0.") { [self] scope in
            scope.setLevel(.warning)
            scope.setTags(["messageUid": messageUid])
            scope.setExtras([
                "givenWidth": givenWidth,
                "frameWidth": view.frame.width,
                "frameHeight": view.frame.height,
                "fromWidthSubscriber": fromWidthSubscriber
            ])
        }
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
        let anchorRect = view.convert(content.rect, from: webView)

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

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            // Fix CSS properties and adapt the mail to the screen size once the resources are loaded
            let readyState = try await webView.evaluateJavaScript(.documentReadyState) as? String
            guard readyState == "complete" else { return }

            hasFinishedLoading = true

            try await webView.evaluateJavaScript(.removeAllProperties)
            try await normalizeMessageWidth(webViewWidth: webView.frame.width)
        }
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

    @Binding var mentionMenuContent: MentionMenuContent?

    var onWebKitProcessTerminated: (() -> Void)?

    func makeUIViewController(context: Context) -> WebViewController {
        let controller = WebViewController(
            messageUid: messageUid,
            openURL: openURL,
            webView: webView,
            onWebKitProcessTerminated: onWebKitProcessTerminated
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: WebViewController, context: Context) {
        guard let mentionMenuContent else {
            uiViewController.resetMentionMenuState()
            return
        }

        uiViewController.presentMentionMenuIfNeeded(mentionMenuContent)
        DispatchQueue.main.async {
            self.mentionMenuContent = nil
        }
    }
}
