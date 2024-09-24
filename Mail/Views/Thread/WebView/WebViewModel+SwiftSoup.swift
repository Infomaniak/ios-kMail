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

import CocoaLumberjackSwift
import MailCore
import SwiftSoup

extension WebViewModel {
    func loadHTMLString(value: String?, blockRemoteContent: Bool) async -> LoadResult {
        guard let rawHTML = value else { return .errorEmptyInputValue }

        do {
            guard let safeDocument = try? await SwiftSoupUtils(fromHTML: rawHTML).cleanCompleteDocument()
            else { return .errorCleanHTMLContent }

            try updateViewportMetaTag(of: safeDocument)
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
            Logger.general.error("An error occurred while parsing body \(error)")
            return .errorParsingBody
        }
    }

    /// Adds a viewport if necessary or change the value of the current one to `Constants.viewportContent`
    private func updateViewportMetaTag(of document: Document) throws {
        let head = document.head()
        if let viewport = try head?.select("meta[name=\"viewport\"]"), !viewport.isEmpty() {
            try viewport.attr("content", Constants.viewportContent)
        } else {
            try head?.append("<meta name=\"viewport\" content=\"\(Constants.viewportContent)\">")
        }
        try head?.append(style)
    }

    /// Wraps the message body in a div
    /// This step is necessary to munge the email contained in the provided id
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
    /// inserts a `<wbr>` Element where a character string can be broken
    private func breakLongWords(of document: Document) throws {
        guard let body = document.body() else { return }
        try breakLongWords(of: body)
    }

    /// Walks through Element nodes and iterates over their TextNodes- Then, if the text requires breakpoints
    /// the TextNode is split into several TextNodes separated by `<wbr>` Elements
    private func breakLongWords(of element: Element) throws {
        let children = element.children()

        for child in children {
            let textNodes = child.textNodes()
            for textNode in textNodes {
                let text = textNode.getWholeText()
                guard text.count > Constants.breakStringsAtLength else { continue }

                let nodesWithWBR = splitStringIntoNodes(text)
                try replaceChildNode(of: child, child: textNode, with: nodesWithWBR)
            }

            try breakLongWords(of: child)
        }
    }

    /// Splits a string into TextNodes separated by `<wbr>` Elements.
    /// The string is cut for each word that is too long or at each specific character  (`Character.isBreakable`)
    private func splitStringIntoNodes(_ text: String) -> [Node] {
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

    private func replaceChildNode(of parent: Element, child: Node, with nodes: [Node]) throws {
        let siblingIndex = child.siblingIndex
        try child.remove()
        try parent.insertChildren(siblingIndex, nodes)
    }

    private func insertTextNode(with buffer: String, in nodes: inout [Node]) {
        nodes.append(TextNode(buffer, nil))
    }

    private func insertBreak(with buffer: inout String, in nodes: inout [Node]) {
        insertTextNode(with: buffer, in: &nodes)
        try? nodes.append(Element(Tag.valueOf("wbr"), ""))
        buffer = ""
    }
}
