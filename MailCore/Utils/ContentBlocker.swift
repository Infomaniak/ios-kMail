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
import InfomaniakRichHTMLEditor
import SwiftSoup
import WebKit

public class ContentBlocker {
    private let allowedHosts = ["infomaniak.com", "infomaniak.ch", "infomaniak.statslive.info"]
    private static let cssURLRegexes = [
        try? NSRegularExpression(
            pattern: #"url\(\s*(['\"]?)(.*?)\1\s*\)"#,
            options: .caseInsensitive
        ),
        try? NSRegularExpression(
            pattern: #"@import\s*(['\"])(.*?)\1"#,
            options: .caseInsensitive
        )
    ].compactMap { $0 }
    private let webView: WKWebView
    private let contentBlockRules: String?

    public init(webView: WKWebView) {
        self.webView = webView

        let rules = [
            ContentRule(action: ContentRuleAction(type: .block), trigger: ContentRuleTrigger(urlFilter: ".*"))
        ] + allowedHosts.map {
            ContentRule(action: ContentRuleAction(type: .ignorePreviousRules),
                        trigger: ContentRuleTrigger(urlFilter: Self.allowedHostURLFilter($0)))
        } + [
            ContentRule(action: ContentRuleAction(type: .ignorePreviousRules),
                        trigger: ContentRuleTrigger(
                            urlFilter: "^\(Bundle(for: RichHTMLEditorView.self).bundleURL.absoluteString).*"
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

        let inlineStyles = try document.select("[style]").map { try $0.attr("style") }
        let embeddedStyles = try document.select("style").map { try $0.html() }
        let cssURLStrings = (inlineStyles + embeddedStyles).flatMap(Self.extractURLsFromCSS)
        if srcListContainsRemoteHosts(cssURLStrings) {
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
        let normalizedHost = host.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        return allowedHosts.contains { normalizedHost == $0 || normalizedHost.hasSuffix(".\($0)") }
    }

    static func allowedHostURLFilter(_ host: String) -> String {
        let escapedHost = NSRegularExpression.escapedPattern(for: host)
        return "^https?://([a-z0-9-]+\\.)*\(escapedHost)(:[0-9]+)?([/?#].*)?$"
    }

    private static func extractURLsFromCSS(_ css: String) -> [String] {
        let range = NSRange(css.startIndex..., in: css)
        return cssURLRegexes.flatMap { regex in
            regex.matches(in: css, range: range).compactMap { match in
                guard let urlRange = Range(match.range(at: 2), in: css) else { return nil }
                return String(css[urlRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
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
