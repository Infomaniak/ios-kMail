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
import MailCore
import SwiftUI
import WebKit

final class WebViewController: UIViewController {
    var model: WebViewModel!
    var messageUid: String!

    private var widthSubject = PassthroughSubject<Double, Never>()
    private var subscriber: AnyCancellable?

    override func loadView() {
        view = model.webView
        view.translatesAutoresizingMaskIntoConstraints = false

        setUpWebView(model.webView)

        subscriber = widthSubject
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { newWidth in
                Task {
                    try await self.normalizeMessageWidth(webViewWidth: CGFloat(newWidth))
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
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif
    }

    private func normalizeMessageWidth(webViewWidth width: CGFloat) async throws {
        _ = try await model.webView.evaluateJavaScript("normalizeMessageWidth(\(width), '\(messageUid ?? "")')")
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // run the JS function `listenToSizeChanges` early. Prevent issues with distant resources not available.
        Task { @MainActor in
            try await webView.evaluateJavaScript("listenToSizeChanges()")
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            // Fix CSS properties and adapt the mail to the screen size
            let readyState = try await webView.evaluateJavaScript("document.readyState") as? String
            guard readyState == "complete" else { return }

            _ = try await webView.evaluateJavaScript("removeAllProperties()")
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
            (view.window?.windowScene?.delegate as? SceneDelegate)?.handleUrlOpen(url)
            return
        }

        if navigationAction.navigationType == .linkActivated {
            if let url = navigationAction.request.url {
                decisionHandler(.cancel)
                UIApplication.shared.open(url)
            }
        } else {
            decisionHandler(.allow)
        }
    }
}

struct WebView: UIViewControllerRepresentable {
    let model: WebViewModel
    let messageUid: String

    func makeUIViewController(context: Context) -> WebViewController {
        let controller = WebViewController()
        controller.model = model
        controller.messageUid = messageUid
        return controller
    }

    func updateUIViewController(_ uiViewController: WebViewController, context: Context) {
        // Not needed
    }
}
