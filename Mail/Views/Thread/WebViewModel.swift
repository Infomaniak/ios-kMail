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

import CocoaLumberjackSwift
import MailCore
import SwiftSoup
import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    @Binding var model: WebViewModel
    @Binding var shortHeight: CGFloat
    @Binding var completeHeight: CGFloat
    @Binding var loading: Bool
    @Binding var withQuote: Bool

    var webView: WKWebView {
        return model.webView
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        private func updateHeight(height: CGFloat) {
            if !parent.withQuote {
                if parent.shortHeight < height {
                    parent.shortHeight = height
                    parent.completeHeight = height
                    withAnimation {
                        parent.loading = false
                    }
                }
            } else if parent.completeHeight < height {
                parent.completeHeight = height
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                let readyState = try await webView.evaluateJavaScript("document.readyState") as? String
                guard readyState == "complete" else { return }

                // Fix email style
                _ = try await webView.evaluateJavaScript("removeAllProperties()")
                _ = try await webView.evaluateJavaScript("normalizeMessageWidth(\(webView.frame.width), \"\")")

                // Get WKWebView height
                let scrollHeight = try await webView.evaluateJavaScript("document.documentElement.scrollHeight") as? CGFloat
                guard let scrollHeight else { return }
                updateHeight(height: scrollHeight)
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
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // needed for UIViewRepresentable
    }
}

class WebViewModel: NSObject, WKScriptMessageHandler {
    let webView: WKWebView

    let viewportContent = "width=device-width, initial-scale=1.0"
    var style: String { "<style>\(Constants.customCSS)</style>" }

    override init() {
        let configuration = WKWebViewConfiguration()
        configuration.dataDetectorTypes = .all
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        configuration.setURLSchemeHandler(URLSchemeHandler(), forURLScheme: URLSchemeHandler.scheme)

        webView = WKWebView(frame: .zero, configuration: configuration)
        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif

        super.init()

        configuration.userContentController.add(self, name: "logHandler")

        loadScripts(configuration: configuration)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "logHandler" {
            print("LOG: \(message.body)")
        }
    }

    func loadHTMLString(value: String?) {
        guard let rawHtml = value else { return }

        do {
            guard let safeDocument = MessageBodyUtils.cleanHtmlContent(rawHtml: rawHtml) else { return }

            try updateHeadContent(of: safeDocument)

            // Wrap in #kmail-message-content
            if let bodyContent = safeDocument.body()?.childNodesCopy() {
                safeDocument.body()?.empty()
                try safeDocument.body()?
                    .appendElement("div").attr("id", Constants.divWrapperId)
                    .insertChildren(-1, bodyContent)
            }

            let finalHtml = try safeDocument.outerHtml()
            webView.loadHTMLString(finalHtml, baseURL: nil)
        } catch {
            DDLogError("An error occurred while parsing body \(error)")
        }
    }

    private func loadScripts(configuration: WKWebViewConfiguration) {
        let debugScript = """
        // ----- DEBUG
        function captureLog(msg) { window.webkit.messageHandlers.logHandler.postMessage(msg); }
        window.console.log = captureLog;
        window.console.info = captureLog;
        // ----- DEBUG
        """
        configuration.userContentController
            .addUserScript(WKUserScript(source: debugScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))

        if let javaScriptBridgeScriptURL = Bundle.main.url(forResource: "javaScriptBridge", withExtension: "js"),
           let javaScriptBridgeScript = try? String(contentsOf: javaScriptBridgeScriptURL) {
            configuration.userContentController
                .addUserScript(WKUserScript(source: javaScriptBridgeScript, injectionTime: .atDocumentStart,
                                            forMainFrameOnly: true))
        }

        if let fixEmailStyleScriptURL = Bundle.main.url(forResource: "fixEmailStyle", withExtension: "js"),
           let fixEmailStyleScript = try? String(contentsOf: fixEmailStyleScriptURL) {
            configuration.userContentController
                .addUserScript(WKUserScript(source: fixEmailStyleScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        }

        if let mungeScript = Constants.mungeEmailScript {
            configuration.userContentController
                .addUserScript(WKUserScript(source: mungeScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        }
    }

    private func updateHeadContent(of document: Document) throws {
        let head = document.head()
        if let viewport = try head?.select("meta[name=\"viewport\"]"), !viewport.isEmpty() {
            try viewport.attr("content", viewportContent)
        } else {
            try head?.append("<meta name=\"viewport\" content=\"\(viewportContent)\">")
        }
        try head?.append(style)
    }
}
