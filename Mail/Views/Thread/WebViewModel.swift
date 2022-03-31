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

import MailCore
import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    typealias UIViewType = WKWebView

    @Binding var model: WebViewModel
    @Binding var dynamicHeight: CGFloat
    var proxy: GeometryProxy

    var webView: WKWebView {
        return model.webView
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
            parent.model.proxy = parent.proxy
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.documentElement.scrollHeight", completionHandler: { height, _ in
                DispatchQueue.main.async {
                    self.parent.dynamicHeight = height as! CGFloat
                }
            })
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
        webView.scrollView.isDirectionalLockEnabled = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = true
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

class WebViewModel: ObservableObject {
    let webView: WKWebView
    var proxy: GeometryProxy?
    let css: String? = try? String(contentsOfFile: Bundle.main.path(forResource: "editor", ofType: "css") ?? "", encoding: .utf8)
        .replacingOccurrences(of: "\n", with: "")
    var meta: String {
        return "<meta name=viewport content=\"\(proxy?.size.width ?? 0), initial-scale=1\"><style type=\"text/css\">\(css)</style>"
    }

    init() {
        let configuration = WKWebViewConfiguration()
        configuration.dataDetectorTypes = .all
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        configuration.setURLSchemeHandler(URLSchemeHandler(), forURLScheme: URLSchemeHandler.scheme)
        webView = WKWebView(frame: .zero, configuration: configuration)
    }

    func loadHTMLString(value: String?) {
        guard let value = value else {
            return
        }
        webView.loadHTMLString(meta + value, baseURL: nil)
    }
}

class URLSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "mail-infomaniak"
    static let domain = "://mail.infomaniak.com"

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let url = urlSchemeTask.request.url!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.scheme = "https"
        var request = URLRequest(url: components!.url!)
        request.addValue(
            "Bearer \(AccountManager.instance.currentAccount.token.accessToken)",
            forHTTPHeaderField: "Authorization"
        )
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let response = response {
                urlSchemeTask.didReceive(response)
            }
            if let data = data {
                urlSchemeTask.didReceive(data)
                urlSchemeTask.didFinish()
            }
            if let error = error {
                urlSchemeTask.didFailWithError(error)
            }
        }
        task.resume()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}
