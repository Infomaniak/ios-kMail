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

import Foundation
import SwiftSoup

extension Whitelist {
    static var extendedWhitelist: Whitelist {
        do {
            let customWhitelist = Whitelist.none()
            let allowedTags = [
                "a",
                "b",
                "blockquote",
                "body",
                "br",
                "caption",
                "center",
                "cite",
                "code",
                "col",
                "colgroup",
                "dd",
                "div",
                "dl",
                "dt",
                "em",
                "h1",
                "h2",
                "h3",
                "h4",
                "h5",
                "h6",
                "head",
                "hr",
                "html",
                "i",
                "img",
                "li",
                "meta",
                "ol",
                "p",
                "pre",
                "q",
                "small",
                "span",
                "strike",
                "strong",
                "style",
                "sub",
                "sup",
                "table",
                "tbody",
                "td",
                "tfoot",
                "th",
                "thead",
                "title",
                "tr",
                "u",
                "ul",
            ]

            for tag in allowedTags {
                try customWhitelist.addTags(tag)
                try customWhitelist.addAttributes(tag, "style", "width", "height", "class", "align")
            }

            try customWhitelist
                .addAttributes("a", "href", "title")
                .addAttributes("blockquote", "cite")
                .addAttributes("col", "span")
                .addAttributes("colgroup", "span")
                .addAttributes("img", "align", "alt", "src", "title")
                .addAttributes("ol", "start", "type")
                .addAttributes("q", "cite")
                .addAttributes("table", "summary")
                .addAttributes("td", "abbr", "axis", "colspan", "rowspan")
                .addAttributes("th", "abbr", "axis", "colspan", "rowspan", "scope")
                .addAttributes("ul", "type")

                .addProtocols("a", "href", "http", "https", "mailto")
                .addProtocols("blockquote", "cite", "http", "https")
                .addProtocols("cite", "cite", "http", "https")
                .addProtocols("q", "cite", "http", "https")
            return customWhitelist
        } catch {
            fatalError("Couldn't init html whitelist")
        }
    }
}
