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

import Foundation
import InfomaniakRichEditor
import SwiftSoup
import WebKit

public class ContentBlocker {
    private let allowedHosts = ["infomaniak.com", "infomaniak.ch", "infomaniak.statslive.info"]
    private let webView: WKWebView
    private let contentBlockRules: String?

    public init(webView: WKWebView) {
        self.webView = webView

        let rules = [
            ContentRule(action: ContentRuleAction(type: .block), trigger: ContentRuleTrigger(urlFilter: ".*"))
        ] + allowedHosts.map {
            ContentRule(action: ContentRuleAction(type: .ignorePreviousRules),
                        trigger: ContentRuleTrigger(urlFilter: $0))
        } + [
            ContentRule(action: ContentRuleAction(type: .ignorePreviousRules), trigger: ContentRuleTrigger(
                urlFilter: "\(Bundle(for: RichEditorView.self).bundleURL.absoluteURL).*"
            ))
        ]

        contentBlockRules = ContentRuleGenerator.generateContentRulesJSON(rules: rules)
    }

    public func documentHasRemoteContent(_ document: Document) throws -> Bool {
        let imgSrcUrlStrings = try document.select("img").map { try $0.attr("src") }
        if srcListContainsRemoteHosts(imgSrcUrlStrings) {
            return true
        }

        let svgSrcUrlStrings = try document.select("svg").map { try $0.attr("src") }
        if srcListContainsRemoteHosts(svgSrcUrlStrings) {
            return true
        }

        return false
    }

    public func srcListContainsRemoteHosts(_ srcList: [String]) -> Bool {
        for src in srcList {
            if let srcURL = URL(string: src),
               let host = srcURL.host,
               !isHostAllowed(host) {
                return true
            }
        }
        return false
    }

    public func setRemoteContentBlocked(_ blocked: Bool) async throws {
        guard blocked else {
            await allowRemoteContent()
            return
        }

        guard let blockRuleList = try await WKContentRuleListStore.default()
            .compileContentRuleList(
                forIdentifier: "blockRemoteContent",
                encodedContentRuleList: contentBlockRules
            ) else { return }

        await addContentRuleList(blockRuleList)
    }

    private func isHostAllowed(_ host: String) -> Bool {
        return allowedHosts.contains { host.hasSuffix($0) }
    }

    @MainActor
    private func allowRemoteContent() {
        webView.configuration.userContentController.removeAllContentRuleLists()
    }

    @MainActor
    private func addContentRuleList(_ contentRuleList: WKContentRuleList) {
        webView.configuration.userContentController.add(contentRuleList)
    }
}
