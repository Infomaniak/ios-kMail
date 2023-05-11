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

public enum MessageWebViewUtils {
    public enum WebViewTarget {
        case message, editor
    }

    public static func generateCSS(for target: WebViewTarget) -> String {
        var resources = "<style>\(Constants.styleCSS)</style>"

        if let fixDisplayCSS = loadCSS(filename: "improveRendering") {
            resources += "<style>\(fixDisplayCSS)</style>"
        }

        if target == .editor {
            if let editorCSS = loadCSS(filename: "editor")  {
                resources += "<style>\(editorCSS)</style>"
            }
        }

        return resources
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

            return cleanedDocument
        } catch {
            DDLogError("An error occurred while parsing body \(error)")
            return nil
        }
    }

    private static func loadCSS(filename: String) -> String? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "css"),
              let css = try? String(contentsOf: url) else { return nil }
        return css.replacingOccurrences(of: "\n", with: "")
    }
}
