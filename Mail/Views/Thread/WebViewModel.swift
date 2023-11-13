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
import Combine
import MailCore
import Sentry
import SwiftSoup
import SwiftUI
import WebKit

final class WebViewModel: NSObject, ObservableObject {
    @Published var webViewHeight: CGFloat = .zero

    @Published var showBlockQuote = false
    @Published var contentLoading = true

    /// Only true the first time the content loads, then false. Eg. when loading subsequent images.
    @Published var initialContentLoading = true
    private var contentLoadingSubscriber: AnyCancellable?

    let webView: WKWebView
    let contentBlocker: ContentBlocker

    private let style: String = MessageWebViewUtils.generateCSS(for: .message)

    enum LoadResult: Equatable {
        case remoteContentBlocked
        case remoteContentAuthorized
        case noRemoteContent
        case errorEmptyInputValue
        case errorCleanHTMLContent
        case errorParsingBody
    }

    override init() {
        webView = WKWebView()
        contentBlocker = ContentBlocker(webView: webView)

        super.init()

        // only register the first flip of contentLoading to false
        contentLoadingSubscriber = $contentLoading
            .filter { $0 == false }
            .prefix(1)
            .sink { _ in
                self.initialContentLoading = false
            }

        setUpWebViewConfiguration()
        loadScripts(configuration: webView.configuration)
    }

    func loadBody(presentableBody: PresentableBody, blockRemoteContent: Bool) async -> LoadResult {
        var messageBody = showBlockQuote ? presentableBody.body?.value : presentableBody.compactBody

        if presentableBody.body?.type == "text/plain" {
            messageBody = createHTMLForPlainText(text: messageBody)
        }

        let loadResult = await loadHTMLString(
            value: messageBody,
            blockRemoteContent: blockRemoteContent
        )
        return loadResult
    }

    private func createHTMLForPlainText(text: String?) -> String {
        guard let text else { return "" }
        do {
            let doc = SwiftSoup.Document.createShell("")
            try doc.body()?.appendElement("pre").text(text)
            return try doc.outerHtml()
        } catch {
            return text
        }
    }

    private func loadHTMLString(value: String?, blockRemoteContent: Bool) async -> LoadResult {
        guard let rawHtml = value else { return .errorEmptyInputValue }

        do {
            guard let safeDocument = MessageWebViewUtils.cleanHtmlContent(rawHtml: rawHtml) else { return .errorCleanHTMLContent }

            try updateHeadContent(of: safeDocument)
            try wrapBody(document: safeDocument, inID: Constants.divWrapperId)
            try breakLongWords(of: safeDocument)

            let finalHtml = try safeDocument.outerHtml()

            try await contentBlocker.setRemoteContentBlocked(blockRemoteContent)
            let hasRemoteContent = try contentBlocker.documentHasRemoteContent(safeDocument)
            await webView.loadHTMLString(finalHtml, baseURL: nil)

            if hasRemoteContent {
                return blockRemoteContent ? .remoteContentBlocked : .remoteContentAuthorized
            } else {
                return .noRemoteContent
            }
        } catch {
            DDLogError("An error occurred while parsing body \(error)")
            return .errorParsingBody
        }
    }

    private func setUpWebViewConfiguration() {
        webView.configuration.dataDetectorTypes = .all
        webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        webView.configuration.setURLSchemeHandler(URLSchemeHandler(), forURLScheme: URLSchemeHandler.scheme)

        webView.configuration.userContentController.add(self, name: JavaScriptMessageTopic.log.rawValue)
        webView.configuration.userContentController.add(self, name: JavaScriptMessageTopic.sizeChanged.rawValue)
        webView.configuration.userContentController.add(self, name: JavaScriptMessageTopic.overScroll.rawValue)
        webView.configuration.userContentController.add(self, name: JavaScriptMessageTopic.error.rawValue)
    }

    private func loadScripts(configuration: WKWebViewConfiguration) {
        var scripts = ["javaScriptBridge", "sizeHandler", "fixEmailStyle"]
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

    /// Adds a viewport if necessary or change the value of the current one to `Constants.viewportContent`
    private func updateHeadContent(of document: Document) throws {
        let head = document.head()
        if let viewport = try head?.select("meta[name=\"viewport\"]"), !viewport.isEmpty() {
            try viewport.attr("content", Constants.viewportContent)
        } else {
            try head?.append("<meta name=\"viewport\" content=\"\(Constants.viewportContent)\">")
        }
        try head?.append(style)
    }

    /// Wraps the message body in a div
    private func wrapBody(document: Document, inID id: String) throws {
        if let bodyContent = document.body()?.childNodesCopy() {
            document.body()?.empty()
            try document.body()?
                .appendElement("div")
                .attr("id", id)
                .insertChildren(-1, bodyContent)
        }
    }

    /// Adds breakpoints if the body contains text with words that are too long
    /// Sometimes the WebView needs indication to break certain content like URLs, so the algorithm
    /// inserts a `<wbr>` Element in places where a character string can be broken
    private func breakLongWords(of document: Document) throws {
        guard let contentDiv = document.body() else { return }
        try breakLongWords(of: contentDiv)
    }

    /// Walks through Element nodes and iterates over its TextNodes, then, if the text requires breakpoints
    /// the TextNode is replaced by several TextNodes separated by `<wbr>` Elements
    private func breakLongWords(of element: Element) throws {
        let children = element.children()

        for child in children {
            let textNodes = child.textNodes()
            for textNode in textNodes {
                let text = textNode.text()
                guard text.count > Constants.breakStringsAtLength else { continue }

                let nodesWithWBR = splitTextNodeWithWBR(in: text)

                let siblingIndex = textNode.siblingIndex
                try textNode.remove()
                try child.insertChildren(siblingIndex, nodesWithWBR)
            }

            try breakLongWords(of: child)
        }
    }

    /// Adds a zero-width space, or ZWSP  (`Constants.zeroWidthSpaceHTML`), to each word that is longer than 30 characters or to
    /// certain specific characters (`Character.isBreakable`)
    private func splitTextNodeWithWBR(in text: String) -> [Node] {
        var nodesArray = [Node]()
        var buffer = ""
        var counter = 0
        var previousCharIsBreakable = false
        for letter in text {
            counter += 1

            guard counter < Constants.breakStringsAtLength else {
                buffer.append(letter)
                insertBreak(with: &buffer, in: &nodesArray)
                counter = 0
                continue
            }

            if letter.isWhitespace {
                counter = 0
            } else if letter.isBreakable {
                previousCharIsBreakable = true
            } else {
                if previousCharIsBreakable {
                    insertBreak(with: &buffer, in: &nodesArray)
                    previousCharIsBreakable = false
                    counter = 0
                }
            }

            buffer.append(letter)
        }
        insertTextNode(with: buffer, in: &nodesArray)

        return nodesArray
    }

    private func insertTextNode(with text: String, in nodes: inout [Node]) {
        nodes.append(TextNode(text, nil))
    }

    private func insertBreak(with text: inout String, in nodes: inout [Node]) {
        insertTextNode(with: text, in: &nodes)
        nodes.append(Element.wbr.copy(parent: nil))
        text = ""
    }
}

extension WebViewModel: WKScriptMessageHandler {
    private enum JavaScriptMessageTopic: String {
        case log, sizeChanged, overScroll, error
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let event = JavaScriptMessageTopic(rawValue: message.name) else { return }
        switch event {
        case .log:
            print(message.body)
        case .sizeChanged:
            updateWebViewHeight(message)
        case .overScroll:
            sendOverScrollMessage(message)
        case .error:
            sendJavaScriptError(message)
        }
    }

    private func updateWebViewHeight(_ message: WKScriptMessage) {
        guard let data = message.body as? [String: CGFloat], let height = data["height"] else { return }

        // On some messages, the size infinitely increases by 1px ?
        // Having a threshold avoids this problem
        if Int(abs(webViewHeight - height)) > Constants.sizeChangeThreshold {
            contentLoading = false
            webViewHeight = height
        }
    }

    private func sendOverScrollMessage(_ message: WKScriptMessage) {
        guard let data = message.body as? [String: Any] else { return }

        SentrySDK.capture(message: "After zooming the mail it can still scroll.") { scope in
            scope.setTags(["messageUid": data["messageId"] as? String ?? ""])
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
    func addUserScript(named filename: String, injectionTime: WKUserScriptInjectionTime, forMainFrameOnly: Bool) {
        if let script = Bundle.main.load(filename: filename, withExtension: "js") {
            addUserScript(WKUserScript(source: script, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly))
        }
    }
}
