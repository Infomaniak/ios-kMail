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
import MailResources
import SwiftSoup

public enum MessageBodyUtils {
    private static let blockquote = "blockquote"

    private static var quoteDescriptors = [
        // Do not detect this quote as long as we can't detect siblings quotes or else a single reply will be missing among the
        // many replies of an Outlook reply "chain", which is worst than simply ignoring it
//        "#divRplyFwdMsg", // Outlook
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

    public static func prepareWithPrintOption(message: Message) async -> PresentableBody? {
        guard let messageBody = message.body else {
            return nil
        }
        let bodyValue = messageBody.value ?? ""

        do {
            let printHeader = try createPrintHeader(message: message)
            let originalDocument = try await SwiftSoup.parse(bodyValue).prependChild(printHeader)

            let bodyFromDoc = try originalDocument.outerHtml()

            let messageBodyQuote = await splitBodyAndQuote(messageBody: bodyFromDoc)

            return PresentableBody(
                body: messageBody,
                compactBody: messageBodyQuote.messageBody,
                quote: messageBodyQuote.quote
            )
        } catch {
            print("error: \(error.localizedDescription)")
        }
        let messageBodyQuote = MessageBodyQuote(messageBody: bodyValue, quote: nil)
        return PresentableBody(body: messageBody, compactBody: messageBodyQuote.messageBody, quote: messageBodyQuote.quote)
    }

    public static func splitBodyAndQuote(messageBody: String) async -> MessageBodyQuote {
        let task = Task {
            do {
                let htmlDocumentWithQuote = try await SwiftSoup.parse(messageBody)
                let htmlDocumentWithoutQuote = try await SwiftSoup.parse(messageBody)

                let blockquoteElement = try findAndRemoveLastParentBlockQuote(htmlDocumentWithoutQuote: htmlDocumentWithoutQuote)
                var currentQuoteDescriptor =
                    try findFirstKnownParentQuoteDescriptor(htmlDocumentWithoutQuote: htmlDocumentWithoutQuote)

                if currentQuoteDescriptor.isEmpty {
                    currentQuoteDescriptor = blockquoteElement == nil ? "" : blockquote
                }

                let (body, quote) = try await splitBodyAndQuote(
                    blockquoteElement: blockquoteElement,
                    htmlDocumentWithQuote: htmlDocumentWithQuote,
                    currentQuoteDescriptor: currentQuoteDescriptor
                )
                return MessageBodyQuote(messageBody: quote?.isEmpty ?? true ? messageBody : body, quote: quote)
            } catch {
                DDLogError("Error splitting blockquote \(error)")
            }
            return MessageBodyQuote(messageBody: messageBody, quote: nil)
        }

        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: UInt64(1.5 * Double(NSEC_PER_SEC)))
            task.cancel()
        }

        let result = await task.value
        timeoutTask.cancel()

        return result
    }

    private static func findAndRemoveLastParentBlockQuote(htmlDocumentWithoutQuote: Document) throws -> Element? {
        let element = try selectLastParentBlockQuote(document: htmlDocumentWithoutQuote)
        try element?.remove()
        return element
    }

    private static func findFirstKnownParentQuoteDescriptor(htmlDocumentWithoutQuote: Document) throws -> String {
        var currentQuoteDescriptor = ""
        for quoteDescriptor in quoteDescriptors {
            let quotedContentElement = try htmlDocumentWithoutQuote.select(quoteDescriptor)
            if !quotedContentElement.isEmpty() {
                try quotedContentElement.remove()
                currentQuoteDescriptor = quoteDescriptor
            }
        }
        return currentQuoteDescriptor
    }

    private static func splitBodyAndQuote(blockquoteElement: Element?, htmlDocumentWithQuote: Document,
                                          currentQuoteDescriptor: String) async throws -> (String, String?) {
        if currentQuoteDescriptor == blockquote {
            for quotedContentElement in try await htmlDocumentWithQuote.select(currentQuoteDescriptor) {
                if try quotedContentElement.outerHtml() == blockquoteElement?.outerHtml() {
                    try quotedContentElement.remove()
                    break
                }
            }
            return try (htmlDocumentWithQuote.outerHtml(), blockquoteElement?.outerHtml())
        } else if !currentQuoteDescriptor.isEmpty {
            let quotedContentElements = try await htmlDocumentWithQuote.select(currentQuoteDescriptor)
            try quotedContentElements.remove()
            return try (htmlDocumentWithQuote.outerHtml(), quotedContentElements.outerHtml())
        } else {
            return try (htmlDocumentWithQuote.outerHtml(), nil)
        }
    }

    private static func createPrintHeader(message: Message) throws -> Element {
        let rootHeaderDiv = try Element(Tag("div"), "").attr("id", "printHeader")
        let firstSeparator = try Element(Tag("hr"), "").attr("style", "color: black")
        let secondSeparator = try Element(Tag("hr"), "").attr("style", "color: LightGray")

        let b64image = MailResourcesAsset.logoText.image.pngData()?.base64EncodedString()

        let iconElement = try Element(Tag("img"), "")
            .attr("src", "data:image/png;base64, \(b64image ?? "")")
            .attr("style", "width: 150px;")

        try rootHeaderDiv.insertChildren(0, [iconElement, firstSeparator])

        if let subject = message.subject {
            let subjectElement = try Element(Tag("b"), "").appendText(subject)
            try rootHeaderDiv.appendChild(subjectElement)
        }

        try rootHeaderDiv.appendChild(secondSeparator)

        var messageDetailsDiv = try Element(Tag("div"), "").attr("style", "margin-bottom: 40px")
        messageDetailsDiv = try insertPrintRecipientField(
            to: messageDetailsDiv,
            prefix: MailResourcesStrings.Localizable.ccTitle,
            recipients: message.cc.toArray()
        )
        messageDetailsDiv = try insertPrintRecipientField(
            to: messageDetailsDiv,
            prefix: MailResourcesStrings.Localizable.toTitle,
            recipients: message.to.toArray()
        )
        messageDetailsDiv = try insertPrintRecipientField(
            to: messageDetailsDiv,
            prefix: MailResourcesStrings.Localizable.fromTitle,
            recipients: message.from.toArray()
        )
        messageDetailsDiv = try insertPrintDateField(
            to: messageDetailsDiv,
            prefix: MailResourcesStrings.Localizable.dateTitle,
            date: message.date.formatted(date: .long, time: .shortened)
        )

        try rootHeaderDiv.appendChild(messageDetailsDiv)
        return rootHeaderDiv
    }

    private static func insertPrintRecipientField(to element: Element, prefix: String,
                                                  recipients: [Recipient]) throws -> Element {
        guard !recipients.isEmpty else { return element }

        let recipientsField = Element(Tag("div"), "")
        let fieldName = try Element(Tag("b"), "").appendText(prefix)
        let recipientsName = recipients.map { $0.htmlDescription }.joined(separator: ", ")
        let fieldValue = try Element(Tag("text"), "").appendText(recipientsName)

        try recipientsField.insertChildren(0, [fieldName, fieldValue])

        return try element.prependChild(recipientsField)
    }

    private static func insertPrintDateField(to element: Element, prefix: String, date: String) throws -> Element {
        let recipientsField = Element(Tag("div"), "")
        let fieldName = try Element(Tag("b"), "").appendText(prefix)
        let fieldValue = try Element(Tag("text"), "").appendText(date)

        try recipientsField.insertChildren(0, [fieldName, fieldValue])

        return try element.prependChild(recipientsField)
    }

    // MARK: - Utils

    /// Some email clients rename css classes to prefix them for example.
    /// We match all the css classes that contain the quote, in case this one has been renamed.
    /// - Returns: A new cssQuery
    private static func anyCssClassContaining(cssClass: String) -> String {
        return "[class*=\(cssClass)]"
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
