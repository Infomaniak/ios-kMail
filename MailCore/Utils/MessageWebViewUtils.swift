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
import MailResources
import SwiftSoup

public enum MessageWebViewUtils {
    public enum WebViewTarget {
        case message(theme: MessageTheme, addresses: [String])
        case editor
    }

    public static func loadAndFormatCSS(for target: WebViewTarget) -> String {
        let loadedCSS = loadCSS(for: target).map { $0.wrapInHTMLTag("style") }
        return loadedCSS.joined()
    }

    public static func loadCSS(for target: WebViewTarget) -> [String] {
        var resources = [String]()

        if let style = MailResourcesResources.bundle.loadCSS(filename: "style") {
            let variables = """
            :root {
                --kmail-primary-color: \(UserDefaults.shared.accentColor.primary.swiftUIColor.hexRepresentation);
            }
            """

            if case .message(let theme, let addresses) = target {
				if theme == .auto {
               		let darkModeCSS = MailResourcesResources.bundle.loadCSS(filename: "darkModeBackground") {
                		resources.append(darkModeCSS)
					}
				}
                variables.append("""
                :root {
                    color-scheme: \(theme.cssProperty);
                }
                """)
                for address in addresses {

                    variables.append("""
                    a[data-ik-mention-ref='\(address)'] {
                        --mail-content-mention-background-color: #ffc9df;
                        --mail-content-mention-text-color: #5f142f;
                        --mail-content-mention-font-weight: 500;
                    }
                    """)
                }
            }

            let processedStyle = "\(variables + style)".replacingOccurrences(of: "\n", with: "")
            resources.append(processedStyle)
        }

        if let fixDisplayCSS = MailResourcesResources.bundle.loadCSS(filename: "improveRendering") {
            resources.append(fixDisplayCSS)
        }

        if case .editor = target, let editorCSS = MailResourcesResources.bundle.loadCSS(filename: "editor"),
           let darkModeCSS = MailResourcesResources.bundle.loadCSS(filename: "darkModeBackground") {
            resources.append(editorCSS)
            resources.append(darkModeCSS)
        }

        return resources
    }

    public static func createHTMLForPlainText(text: String) async throws -> String {
        guard let root = try await SwiftSoupUtils(fromHTMLFragment: "<pre>").extractParentElement() else { return "" }
        try root.text(text)
        return try root.outerHtml()
    }
}
