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

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    @ObservedObject var model: WebViewModel

    let messageUid: String

    var webView: WKWebView {
        return model.webView
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        private func updateHeight(height: CGFloat) {
            if !parent.model.showBlockQuote {
                if parent.model.webViewShortHeight < height {
                    parent.model.webViewShortHeight = height
                    parent.model.webViewCompleteHeight = height
                    withAnimation {
                        parent.model.contentLoading = false
                    }
                }
            } else if parent.model.webViewCompleteHeight < height {
                parent.model.webViewCompleteHeight = height
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                let readyState = try await webView.evaluateJavaScript("document.readyState") as? String
                guard readyState == "complete" else { return }

                // Fix email style
                _ = try await webView.evaluateJavaScript("removeAllProperties()")
                _ = try await webView.evaluateJavaScript("normalizeMessageWidth(\(webView.frame.width), '\(parent.messageUid)')")

                // Get WKWebView height
                let scrollHeight = try await webView.evaluateJavaScript("document.documentElement.scrollHeight") as? CGFloat
                guard let scrollHeight else { return }
                updateHeight(height: scrollHeight)

                try await webView.evaluateJavaScript("displayImproved()")
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
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

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = true
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.alwaysBounceHorizontal = false
        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // needed for UIViewRepresentable
    }
}
