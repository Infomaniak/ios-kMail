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
    case observeInlineAttachmentsDeletion
    case observeMention
    case observeMentionDeletion
    case observeMentionClick
    case insertMention
    case mentionCommon
    case editorMentionPointerEventHandler
}

public enum JavaScriptDeclaration {
    case normalizeMessageWidth(CGFloat, String)
    case removeAllProperties
    case documentReadyState
    case insertMention(String, String, String)
    case setScaleCompensation(CGFloat)
    case setContentSize(CGFloat)

    public var functionBody: String {
        switch self {
        case .normalizeMessageWidth:
            return "normalizeMessageWidth(width, messageUid);"
        case .removeAllProperties:
            return "removeAllProperties();"
        case .documentReadyState:
            return "return document.readyState;"
        case .insertMention:
            return "insertMention(email, name, query);"
        case .setScaleCompensation:
            return "setScaleCompensation(factor);"
        case .setContentSize:
            return "setContentSize(size);"
        }
    }

    public var arguments: [String: Any] {
        switch self {
        case .normalizeMessageWidth(let width, let messageUid):
            return ["width": Double(width), "messageUid": messageUid]
        case .removeAllProperties, .documentReadyState:
            return [:]
        case .insertMention(let email, let name, let query):
            return ["email": email, "name": name, "query": query]
        case .setScaleCompensation(let factor):
            return ["factor": Double(factor)]
        case .setContentSize(let size):
            return ["size": Double(size)]
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
