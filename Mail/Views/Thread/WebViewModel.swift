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
    typealias UIViewType = WKWebView

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

class WebViewModel {
    let webView: WKWebView
    let css: String? = try? String(contentsOfFile: Bundle.main.path(forResource: "style", ofType: "css") ?? "", encoding: .utf8)
        .replacingOccurrences(of: "\n", with: "")
    var viewport: String {
        return "<meta name=viewport content=\"width=device-width, initial-scale=1, shrink-to-fit=YES\">"
    }

    var style: String {
        return "<style>\(css ?? "")</style>"
    }

    init() {
        let configuration = WKWebViewConfiguration()
        configuration.dataDetectorTypes = .all
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        configuration.setURLSchemeHandler(URLSchemeHandler(), forURLScheme: URLSchemeHandler.scheme)
        webView = WKWebView(frame: .zero, configuration: configuration)
    }

    func loadHTMLString(value: String?) {
        guard let rawHtml = value else {
            return
        }

        do {
            guard let safeHtml = MessageBodyUtils.cleanHtmlContent(rawHtml: rawHtml) else { return }
            let parsedHtml = try SwiftSoup.parse(safeHtml)

            let head: Element
            if let existingHead = parsedHtml.head() {
                head = existingHead
            } else {
                head = try parsedHtml.appendElement("head")
            }

            let allImages = try parsedHtml.select("img[width]").array()
            let maxWidth = webView.frame.width
            for image in allImages {
                if let widthString = image.getAttributes()?.get(key: "width"),
                   let width = Double(widthString),
                   width > maxWidth {
                    try image.attr("width", "\(maxWidth)")
                    try image.attr("height", "auto")
                }
            }

            try head.append(viewport)
            try head.append(style)

            let finalHtml = try parsedHtml.html()

            webView.loadHTMLString(finalHtml, baseURL: nil)
        } catch {
            DDLogError("An error occurred while parsing body \(error)")
        }
    }
}
