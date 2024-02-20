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
import RealmSwift
import Sentry
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

    let style: String = MessageWebViewUtils.generateCSS(for: .message)

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

    func loadBody(presentableBody: PresentableBody, blockRemoteContent: Bool, messageUid: String) async throws -> LoadResult {
        var messageBody = showBlockQuote ? presentableBody.body?.value : presentableBody.compactBody

        if messageBody != nil, let subBodies = presentableBody.body?.subBody {
            messageBody! += formatSubBodyContent(subBodies: subBodies, messageUid: messageUid)
        }

        let loadResult = await loadHTMLString(value: messageBody, blockRemoteContent: blockRemoteContent)
        return loadResult
    }

    private func formatSubBodyContent(subBodies: List<SubBody>, messageUid: String) -> String {
        var subBodiesContent = ""
        for subBody in subBodies {
            guard let bodyValue = subBody.value else {
                continue
            }
            if !subBodiesContent.isEmpty {
                subBodiesContent += "<br/>"
            }
            subBodiesContent += "<blockquote>\(bodyValue)</blockquote>"
        }

        if !subBodiesContent.isEmpty {
            SentryDebug.sendSubBodiesTrigger(messageUid: messageUid)
        }

        return subBodiesContent
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
        #if DEBUG || TEST
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
}
