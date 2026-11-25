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
    case fixEmailContrast
    case captureLog
    case observeInlineAttachmentsDeletion
    case observeMention
    case observeMentionDeletion
    case observeMentionClick
    case insertMention
    case mentionCommon
    case editorMentionPointerEventHandler
    case insertHTMLAtCaret
}

public enum JavaScriptDeclaration {
    case normalizeMessage(
        width: CGFloat,
        messageUid: String,
        contentSize: CGFloat,
        scaleCompensation: CGFloat,
        shouldRemoveAllProperties: Bool
    )
    case removeAllProperties
    case insertMention(String, String, String)
    case insertHTMLAtCaret(String)
    case applyEmailDarkModeContrast

    public var functionBody: String {
        switch self {
        case .normalizeMessage:
            return "return normalizeMessage(width, messageUid, contentSize, scaleCompensation, shouldRemoveAllProperties);"
        case .removeAllProperties:
            return "removeAllProperties();"
        case .insertMention:
            return "insertMention(email, name, query);"
        case .insertHTMLAtCaret:
            return "return insertHTMLAtCaret(html);"
        case .applyEmailDarkModeContrast:
            return "applyEmailDarkModeContrast();"
        }
    }

    public var arguments: [String: Any] {
        switch self {
        case .normalizeMessage(let width, let messageUid, let contentSize, let scaleCompensation, let shouldRemove):
            return [
                "width": Double(width),
                "messageUid": messageUid,
                "contentSize": Double(contentSize),
                "scaleCompensation": Double(scaleCompensation),
                "shouldRemoveAllProperties": shouldRemove
            ]
        case .removeAllProperties, .applyEmailDarkModeContrast:
            return [:]
        case .insertMention(let email, let name, let query):
            return ["email": email, "name": name, "query": query]
        case .insertHTMLAtCaret(let html):
            return ["html": html]
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
        return try await callAsyncJavaScript(
            declaration.functionBody,
            arguments: declaration.arguments,
            in: nil,
            contentWorld: .page
        )
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
