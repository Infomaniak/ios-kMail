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
import Foundation
import SwiftSoup

public enum MessageBodyUtils {
    private static let blockquote = "blockquote"

    private static var quoteDescriptors = [
        "#divRplyFwdMsg", // Outlook
        "#isForwardContent",
        "#isReplyContent",
        "#mailcontent:not(table)",
        "#origbody",
        "#oriMsgHtmlSeperator",
        "#reply139content",
        anyCssClassContaining(cssClass: "gmail_extra"),
        anyCssClassContaining(cssClass: "gmail_quote"),
        anyCssClassContaining(cssClass: "ik_mail_quote"),
        anyCssClassContaining(cssClass: "moz-cite-prefix"),
        anyCssClassContaining(cssClass: "protonmail_quote"),
        anyCssClassContaining(cssClass: "yahoo_quoted"),
        anyCssClassContaining(cssClass: "zmail_extra"), // Zoho
        "[name=\"quote\"]", // GMX
        "blockquote[type=\"cite\"]"
    ]

    public static func splitBodyAndQuote(messageBody: String) -> MessageBodyQuote? {
        do {
            let htmlDocumentWithQuote = try SwiftSoup.parse(messageBody)
            let htmlDocumentWithoutQuote = try SwiftSoup.parse(messageBody)

            let blockquoteElement = try findAndRemoveLastParentBlockQuote(htmlDocumentWithoutQuote: htmlDocumentWithoutQuote)
            var currentQuoteDescriptor =
                try findFirstKnownParentQuoteDescriptor(htmlDocumentWithoutQuote: htmlDocumentWithoutQuote)

            if currentQuoteDescriptor.isEmpty {
                currentQuoteDescriptor = blockquoteElement == nil ? "" : blockquote
            }

            let (body, quote) = try splitBodyAndQuote(
                blockquoteElement: blockquoteElement,
                htmlDocumentWithQuote: htmlDocumentWithQuote,
                currentQuoteDescriptor: currentQuoteDescriptor
            )
            return MessageBodyQuote(messageBody: quote?.isEmpty ?? true ? messageBody : body, quote: quote)
        } catch {
            DDLogError("Error splitting blockquote \(error)")
        }
        return nil
    }

    public static func cleanHtmlContent(rawHtml: String) -> Document? {
        do {
            let dirtyDocument = try SwiftSoup.parse(rawHtml)
            let cleanedDocument = try SwiftSoup.Cleaner(headWhitelist: .headWhitelist, bodyWhitelist: .extendedBodyWhitelist)
                .clean(dirtyDocument)

            // We need to remove the tag <meta http-equiv="refresh" content="x">
            let metaRefreshTags = try cleanedDocument.select("meta[http-equiv='refresh']")
            for metaRefreshTag in metaRefreshTags {
                try metaRefreshTag.parent()?.removeChild(metaRefreshTag)
            }

            // If `<body>` has a style attribute, keep it
            if let bodyStyleAttribute = try dirtyDocument.body()?.attr("style") {
                try cleanedDocument.body()?.attr("style", bodyStyleAttribute)
            }

            return try cleanedDocument
        } catch {
            DDLogError("An error occurred while parsing body \(error)")
            return nil
        }
    }

    private static func findAndRemoveLastParentBlockQuote(htmlDocumentWithoutQuote: Document) throws -> Element? {
        let element = try selectLastParentBlockQuote(document: htmlDocumentWithoutQuote)
        try element?.remove()
        return element
    }

    private static func findFirstKnownParentQuoteDescriptor(htmlDocumentWithoutQuote: Document) throws -> String {
        var currentQuoteDescriptor = ""
        for quoteDescriptor in quoteDescriptors {
            let quotedContentElement = try selectElementAndFollowingSiblings(
                document: htmlDocumentWithoutQuote,
                quoteDescriptor: quoteDescriptor
            )
            if !quotedContentElement.isEmpty() {
                try quotedContentElement.remove()
                currentQuoteDescriptor = quoteDescriptor
            }
        }
        return currentQuoteDescriptor
    }

    private static func splitBodyAndQuote(blockquoteElement: Element?, htmlDocumentWithQuote: Document,
                                          currentQuoteDescriptor: String) throws -> (String, String?) {
        if currentQuoteDescriptor == blockquote {
            for quotedContentElement in try htmlDocumentWithQuote.select(currentQuoteDescriptor) {
                if try quotedContentElement.outerHtml() == blockquoteElement?.outerHtml() {
                    try quotedContentElement.remove()
                    break
                }
            }
            return try (htmlDocumentWithQuote.outerHtml(), blockquoteElement?.outerHtml())
        } else if !currentQuoteDescriptor.isEmpty {
            let quotedContentElements = try selectElementAndFollowingSiblings(
                document: htmlDocumentWithQuote,
                quoteDescriptor: currentQuoteDescriptor
            )
            try quotedContentElements.remove()
            return try (htmlDocumentWithQuote.outerHtml(), quotedContentElements.outerHtml())
        } else {
            return try (htmlDocumentWithQuote.outerHtml(), nil)
        }
    }

    // MARK: - Utils

    /// Some email clients rename css classes to prefix them for example.
    /// We match all the css classes that contain the quote, in case this one has been renamed.
    /// - Returns: A new cssQuery
    private static func anyCssClassContaining(cssClass: String) -> String {
        return "[class*=\(cssClass)]"
    }

    /// Some mail clients add the history in a new block, at the same level as the old one.
    /// And so we match the current block, as well as all those that follow and that are at the same level
    /// - Returns: [Elements] containing all the blocks that have been matched
    private static func selectElementAndFollowingSiblings(document: Document, quoteDescriptor: String) throws -> Elements {
        return try document.select("\(quoteDescriptor), \(quoteDescriptor) ~ *")
    }

    private static func selectLastParentBlockQuote(document: Document) throws -> Element? {
        return try document.select("\(blockquote):not(\(blockquote) \(blockquote)):last-of-type").first()
    }
}

public struct MessageBodyQuote {
    public let messageBody: String
    public let quote: String?

    public init(messageBody: String, quote: String?) {
        self.messageBody = messageBody
        self.quote = quote
    }
}
