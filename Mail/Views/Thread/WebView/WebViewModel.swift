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
import MailCore
import MailResources
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

    let style = MessageWebViewUtils.loadAndFormatCSS(for: .message)

    enum LoadResult: Equatable {
        case remoteContentBlocked
        case remoteContentAuthorized
        case noRemoteContent
        case errorEmptyInputValue
        case errorCleanHTMLContent
        case errorParsingBody
    }

    override init() {
        let configuration = WKWebViewConfiguration()
        configuration.dataDetectorTypes = .all
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        configuration.setURLSchemeHandler(URLSchemeHandler(), forURLScheme: URLSchemeHandler.scheme)

        webView = WKWebView(frame: .zero, configuration: configuration)
        contentBlocker = ContentBlocker(webView: webView)

        super.init()

        // only register the first flip of contentLoading to false
        contentLoadingSubscriber = $contentLoading
            .filter { $0 == false }
            .prefix(1)
            .sink { _ in
                self.initialContentLoading = false
            }

        registerJavaScriptMessageTopics()
        loadScripts()
    }

    func loadBody(presentableBody: PresentableBody, blockRemoteContent: Bool) async -> LoadResult {
        var messageBody = showBlockQuote ? presentableBody.body?.value : presentableBody.compactBody

        if messageBody != nil, let subBodies = presentableBody.body?.subBody {
            messageBody! += formatSubBodyContent(subBodies: subBodies)
        }

        let loadResult = await loadHTMLString(value: messageBody, blockRemoteContent: blockRemoteContent)
        return loadResult
    }

    private func formatSubBodyContent(subBodies: List<SubBody>) -> String {
        let subBodiesContent = subBodies.reduce("") {
            var partialResult = $0

            guard let bodyValue = $1.value else {
                return partialResult
            }

            if !partialResult.isEmpty {
                partialResult += "<br/>"
            }
            return partialResult + "<blockquote>\(bodyValue)</blockquote>"
        }

        return subBodiesContent
    }

    private func registerJavaScriptMessageTopics() {
        for messageTopic in JavaScriptMessageTopic.allCases {
            webView.configuration.userContentController.add(self, name: messageTopic.rawValue)
        }
    }

    private func loadScripts() {
        var scripts: [UserScript] = [.javaScriptBridge, .sizeHandler, .fixEmailStyle]
        #if DEBUG
        scripts.insert(.captureLog, at: 0)
        #endif

        for script in scripts {
            webView.loadUserScript(script)
        }

        if let mungeScript = Constants.mungeEmailScript {
            webView.configuration.userContentController
                .addUserScript(WKUserScript(source: mungeScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        }
    }
}
