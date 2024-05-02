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
    private static var quoteDescriptors = [
        // The reply and forward #divRplyFwdMsg div only contains the header.
        // The previous message body is written right next to this div and can't be detected
        // "#divRplyFwdMsg", // Outlook
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
        "blockquote[type=\"cite\"]" // iOS and macOS Mail
    ]

    public static func prepareWithPrintOption(message: Message) async -> PresentableBody? {
        guard let messageBody = message.body else {
            return nil
        }
        var bodyValue = messageBody.value ?? ""

        do {
            if messageBody.type == .textPlain {
                bodyValue = try await MessageWebViewUtils.createHTMLForPlainText(text: bodyValue)
            }
            bodyValue = try await prependPrintHeader(to: bodyValue, with: message)

            let messageBodyQuote = await splitBodyAndQuote(messageBody: bodyValue)

            return PresentableBody(
                body: messageBody,
                compactBody: messageBodyQuote.messageBody,
                quotes: messageBodyQuote.quotes
            )
        } catch {
            print("error: \(error.localizedDescription)")
        }
        let messageBodyQuote = MessageBodyQuote(messageBody: bodyValue)
        return PresentableBody(body: messageBody, compactBody: messageBodyQuote.messageBody, quotes: messageBodyQuote.quotes)
    }

    public static func splitContentAndQuote(body: String) async throws -> (String, [String]) {
        let parsedBody = try await SwiftSoup.parse(body)

        var quotes = [String]()
        for quoteDescriptor in quoteDescriptors {
            let foundQuotes = try await parsedBody.select(quoteDescriptor)
            for foundQuote in foundQuotes {
                try quotes.append(foundQuote.outerHtml())
                try foundQuote.remove()
            }
        }

        return try (parsedBody.outerHtml(), quotes)
    }

    public static func splitBodyAndQuote(messageBody: String) async -> MessageBodyQuote {
        let task = Task {
            do {
                return try await extractQuotesFromBody(messageBody)
            } catch {
                DDLogError("Error splitting blockquote \(error)")
                return MessageBodyQuote(messageBody: messageBody)
            }
        }

        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: UInt64(1.5 * Double(NSEC_PER_SEC)))
            task.cancel()
        }

        let result = await task.value
        timeoutTask.cancel()

        return result
    }

    private static func extractQuotesFromBody(_ body: String) async throws -> MessageBodyQuote {
        let parsedBody = try await SwiftSoup.parse(body)

        var quotes = [String]()
        for quoteDescriptor in quoteDescriptors {
            let foundQuotes = try await parsedBody.select(quoteDescriptor)
            for foundQuote in foundQuotes {
                try quotes.append(foundQuote.outerHtml())
                try foundQuote.remove()
            }
        }

        return try MessageBodyQuote(messageBody: parsedBody.outerHtml(), quotes: quotes)
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

    public static func prependPrintHeader(to body: String, with message: Message) async throws -> String {
        let parsedBody = try await SwiftSoup.parse(body)
        let printHeader = try createPrintHeader(message: message)
        let originalDocument = try parsedBody.prependChild(printHeader)
        return try originalDocument.outerHtml()
    }

    // MARK: - Utils

    /// Some email clients rename css classes to prefix them for example.
    /// We match all the css classes that contain the quote, in case this one has been renamed.
    /// - Returns: A new cssQuery
    private static func anyCssClassContaining(cssClass: String) -> String {
        return "[class*=\(cssClass)]"
    }
}

public struct MessageBodyQuote {
    public let messageBody: String
    public let quotes: [String]

    public init(messageBody: String, quotes: [String] = []) {
        self.messageBody = messageBody
        self.quotes = quotes
    }
}
