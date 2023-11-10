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
    static var headWhitelist: Whitelist {
        do {
            let customWhitelist = Whitelist.none()
            try customWhitelist
                .addTags("base", "meta", "style", "title", "wbr")
                .addAttributes("style", "media", "type")
                .addAttributes("meta", "charset", "content", "http-equiv", "name")
                .addAttributes("base", "href", "target")
                .addProtocols("base", "href", "http", "https")

            return customWhitelist
        } catch {
            fatalError("Couldn't init head whitelist")
        }
    }

    static var extendedBodyWhitelist: Whitelist {
        do {
            let customWhitelist = try Whitelist.relaxed()
            try customWhitelist
                .addTags(
                    "area",
                    "button",
                    "center",
                    "del",
                    "font",
                    "hr",
                    "ins",
                    "kbd",
                    "map",
                    "title",
                    "tt",
                    "samp",
                    "style",
                    "var"
                )
                .addAttributes(":all", "class", "dir", "id", "style")
                .addAttributes("a", "name")
                // Allow all URI schemes in links. Removing all protocols makes the list of protocols empty which means allow all
                // protocols
                .removeProtocols("a", "href", "ftp", "http", "https", "mailto")
                .addAttributes("area", "alt", "coords", "href", "shape")
                .addProtocols("area", "href", "http", "https")
                .addAttributes("body", "lang", "alink", "background", "bgcolor", "link", "text", "vlink")
                .addAttributes("div", "align")
                .addAttributes("font", "color", "face", "size")
                .addAttributes("img", "usemap")
                .addProtocols("img", "src", "cid", "data", "http", "https")
                .addAttributes("map", "name")
                .addAttributes("table", "align", "background", "bgcolor", "border", "cellpadding", "cellspacing", "width")
                .addAttributes("tr", "align", "background", "bgcolor", "valign")
                .addAttributes(
                    "th",
                    "align", "background", "bgcolor", "colspan", "headers", "height", "nowrap", "rowspan", "scope",
                    "sorted", "valign", "width"
                )
                .addAttributes(
                    "td",
                    "align", "background", "bgcolor", "colspan", "headers", "height", "nowrap", "rowspan", "scope",
                    "valign", "width"
                )

            return customWhitelist
        } catch {
            fatalError("Couldn't init body whitelist")
        }
    }
}
