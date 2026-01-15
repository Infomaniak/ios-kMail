/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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
import WebKit

public enum UserScript: String {
    case javaScriptBridge
    case sizeHandler
    case fixEmailStyle
    case captureLog
}

public enum JavaScriptDeclaration {
    case normalizeMessageWidth(CGFloat, String)
    case removeAllProperties
    case documentReadyState

    public var invocation: String {
        switch self {
        case .normalizeMessageWidth(let width, let messageUid):
            return "normalizeMessageWidth(\(width), '\(messageUid)')"
        case .removeAllProperties:
            return "removeAllProperties()"
        case .documentReadyState:
            return "document.readyState"
        }
    }
}

public extension WKWebView {
    func loadUserScript(_ userScript: UserScript, bundle: Bundle = MailResourcesResources.bundle) {
        configuration.userContentController.addUserScript(
            named: userScript.rawValue,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true,
            bundle: bundle
        )
    }

    @discardableResult
    func evaluateJavaScript(_ declaration: JavaScriptDeclaration) async throws -> Any? {
        return try await evaluateJavaScript(declaration.invocation)
    }
}

public extension WKUserContentController {
    func addUserScript(
        named filename: String,
        injectionTime: WKUserScriptInjectionTime,
        forMainFrameOnly: Bool,
        bundle: Bundle = MailResourcesResources.bundle
    ) {
        if let script = bundle.load(filename: filename, withExtension: "js") {
            addUserScript(WKUserScript(source: script, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly))
        }
    }
}
