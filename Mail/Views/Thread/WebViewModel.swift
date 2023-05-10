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
import Sentry
import SwiftSoup
import SwiftUI
import WebKit

class WebViewModel: NSObject {
    let webView: WKWebView

    private let viewportContent = "width=device-width, initial-scale=1.0"
    private let style = "<style>\(Constants.customCSS)</style>"

    override init() {
        webView = WKWebView()

        super.init()

        setUpWebViewConfiguration()
        loadScripts(configuration: webView.configuration)
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
                    .appendElement("div")
                    .attr("id", Constants.divWrapperId)
                    .insertChildren(-1, bodyContent)
            }

            let finalHtml = try safeDocument.outerHtml()
            webView.loadHTMLString(finalHtml, baseURL: nil)
        } catch {
            DDLogError("An error occurred while parsing body \(error)")
        }
    }

    private func setUpWebViewConfiguration() {
        webView.configuration.dataDetectorTypes = .all
        webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        webView.configuration.setURLSchemeHandler(URLSchemeHandler(), forURLScheme: URLSchemeHandler.scheme)

        webView.configuration.userContentController.add(self, name: JavaScriptMessageTopic.log.rawValue)
        webView.configuration.userContentController.add(self, name: JavaScriptMessageTopic.overScroll.rawValue)
        webView.configuration.userContentController.add(self, name: JavaScriptMessageTopic.error.rawValue)
    }

    private func loadScripts(configuration: WKWebViewConfiguration) {
        var scripts = ["javaScriptBridge", "fixEmailStyle"]
        #if DEBUG
        scripts.insert("captureLog", at: 0)
        #endif

        for script in scripts {
            configuration.userContentController
                .addUserScript(named: script, injectionTime: .atDocumentStart, forMainFrameOnly: true)
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

extension WebViewModel: WKScriptMessageHandler {
    private enum JavaScriptMessageTopic: String {
        case log, overScroll, error
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let event = JavaScriptMessageTopic(rawValue: message.name) else { return }
        switch event {
        case .log:
            print(message.body)
        case .overScroll:
            sendOverScrollMessage(message)
        case .error:
            sendJavaScriptError(message)
        }
    }

    private func sendOverScrollMessage(_ message: WKScriptMessage) {
        guard let data = message.body as? [String: String] else { return }

        SentrySDK.capture(message: "After zooming the mail it can still scroll.") { scope in
            scope.setTags(["messageUid": data["messageId"] ?? ""])
            scope.setExtras([
                "clientWidth": data["clientWidth"],
                "scrollWidth": data["scrollWidth"]
            ])
        }
    }

    private func sendJavaScriptError(_ message: WKScriptMessage) {
        guard let data = message.body as? [String: String] else { return }

        SentrySDK.capture(message: "JavaScript returned an error when displaying an email.") { scope in
            scope.setTags(["messageUid": data["messageId"] ?? ""])
            scope.setExtras([
                "errorName": data["errorName"],
                "errorMessage": data["errorMessage"],
                "errorStack": data["errorStack"]
            ])
        }
    }
}

extension WKUserContentController {
    func addUserScript(named name: String, injectionTime: WKUserScriptInjectionTime, forMainFrameOnly: Bool) {
        if let url = Bundle.main.url(forResource: name, withExtension: "js"), let script = try? String(contentsOf: url) {
            addUserScript(WKUserScript(source: script, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly))
        }
    }
}
