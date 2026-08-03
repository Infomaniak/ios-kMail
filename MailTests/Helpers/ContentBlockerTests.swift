/*
 Infomaniak Mail - iOS App
 Copyright (C) 2026 Infomaniak Network SA

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
@testable import MailCore
import SwiftSoup
import Testing
import WebKit

@Suite
@MainActor
struct ContentBlockerTests {
    private let contentBlocker = ContentBlocker(webView: WKWebView())

    @Test("Allowed host URL filter matches allowed hosts only")
    func allowedHostURLFilterMatchesAllowedHostsOnly() throws {
        let allowedURLs = [
            "https://infomaniak.com/pixel.gif",
            "https://a.infomaniak.com/pixel.gif",
            "http://assets.mail.infomaniak.com:8080/pixel.gif?value=1",
            "https://infomaniak.com?value=1"
        ]
        let disallowedURLs = [
            "https://tracker.example/pixel.gif?allow=https://a.infomaniak.com",
            "https://evilinfomaniak.com/pixel.gif",
            "https://infomaniak.com.evil.example/pixel.gif",
            "https://infomaniak.com:password@tracker.example/pixel.gif",
            "https://infomaniak.com@evil.example/pixel.gif"
        ]
        let filter = ContentBlocker.allowedHostURLFilter("infomaniak.com")

        for url in allowedURLs {
            #expect(try filter.matchesEntireString(url), "Expected filter to allow \(url)")
        }
        for url in disallowedURLs {
            #expect(try !filter.matchesEntireString(url), "Expected filter to block \(url)")
        }
    }

    @Test("Document has remote content for inline background image")
    func documentHasRemoteContentForInlineBackgroundImage() throws {
        let document = try SwiftSoup.parse(
            #"<div style="background-image:url('https://tracker.example/pixel.gif?id=1&amp;allow=https://a.infomaniak.com')"></div>"#
        )

        #expect(try contentBlocker.documentHasRemoteContent(document))
    }

    @Test("Document has remote content for embedded style")
    func documentHasRemoteContentForEmbeddedStyle() throws {
        let document = try SwiftSoup.parse(
            #"<style>.pixel { background: url("https://tracker.example/pixel.gif") }</style>"#
        )

        #expect(try contentBlocker.documentHasRemoteContent(document))
    }

    @Test("Document has remote content for quoted CSS import")
    func documentHasRemoteContentForQuotedCSSImport() throws {
        let document = try SwiftSoup.parse(
            #"<style>@import "https://tracker.example/tracking.css";</style>"#
        )

        #expect(try contentBlocker.documentHasRemoteContent(document))
    }

    @Test("Document does not have remote content for allowed or embedded images")
    func documentDoesNotHaveRemoteContentForAllowedOrEmbeddedImages() throws {
        let documents = [
            #"<div style="background-image: url('https://a.infomaniak.com/image.png')"></div>"#,
            #"<div style="background-image: url(data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==)"></div>"#,
            #"<img src="cid:message-image">"#
        ]

        for html in documents {
            let document = try SwiftSoup.parse(html)
            #expect(
                try !contentBlocker.documentHasRemoteContent(document),
                "Expected embedded or allowed image for \(html)"
            )
        }
    }

    @Test("Source host validation requires a domain boundary")
    func sourceHostValidationRequiresDomainBoundary() {
        #expect(!contentBlocker.srcListContainsRemoteHosts(["https://infomaniak.com/image.png"]))
        #expect(!contentBlocker.srcListContainsRemoteHosts(["https://a.infomaniak.com/image.png"]))
        #expect(contentBlocker.srcListContainsRemoteHosts(["https://evilinfomaniak.com/image.png"]))
        #expect(contentBlocker.srcListContainsRemoteHosts(["https://tracker.example/image.png?allow=infomaniak.com"]))
    }
}

private extension String {
    func matchesEntireString(_ value: String) throws -> Bool {
        let regex = try NSRegularExpression(pattern: self, options: .caseInsensitive)
        let range = NSRange(value.startIndex..., in: value)
        return regex.firstMatch(in: value, range: range)?.range == range
    }
}
