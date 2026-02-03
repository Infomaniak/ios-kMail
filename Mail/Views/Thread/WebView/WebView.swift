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
        try await webView.evaluateJavaScript(.normalizeMessageWidth(width, messageUid))

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

struct WebView: UIViewControllerRepresentable {
    @Environment(\.openURL) private var openURL

    let webView: WKWebView
    let messageUid: String
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
        // Not needed
    }
}
