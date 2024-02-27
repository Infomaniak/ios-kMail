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

import Alamofire
import Foundation
import InfomaniakCore

// AI feature requests take longer to respond. In this case, we increase the timeout
extension MailApiFetcher {
    private func authenticatedAIRequest(_ endpoint: Endpoint, method: HTTPMethod = .get,
                                        parameters: Parameters? = nil) -> DataRequest {
        return authenticatedRequest(
            endpoint,
            method: method,
            parameters: parameters
        ) {
            $0.timeoutInterval = Constants.longTimeout
        }
    }

    private func authenticatedAIRequest<Parameters: Encodable>(
        _ endpoint: Endpoint,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil
    ) -> DataRequest {
        return authenticatedRequest(
            endpoint,
            method: method,
            parameters: parameters
        ) {
            $0.timeoutInterval = Constants.longTimeout
        }
    }
}

/// implementing `MailApiAIFetchable`
public extension MailApiFetcher {
    func aiCreateConversation(
        messages: [AIMessage],
        output: AIOutputFormat = .mail,
        engine: AIEngine,
        mailbox: Mailbox
    ) async throws -> AIConversationResponse {
        try await perform(request: authenticatedAIRequest(
            .ai(mailbox: mailbox),
            method: .post,
            parameters: AIConversationRequest(messages: messages, output: output, engine: engine)
        ))
    }

    func aiShortcut(contextId: String, shortcut: AIShortcutAction, engine: AIEngine,
                    mailbox: Mailbox) async throws -> AIShortcutResponse {
        try await perform(request: authenticatedRequest(
            .aiShortcut(contextId: contextId, shortcut: shortcut.apiName, mailbox: mailbox),
            method: .patch,
            parameters: AIShortcutRequest(engine: engine)
        ))
    }

    func aiShortcutAndRecreateConversation(
        shortcut: AIShortcutAction,
        messages: [AIMessage],
        output: AIOutputFormat = .mail,
        engine: AIEngine,
        mailbox: Mailbox
    ) async throws -> AIShortcutResponse {
        try await perform(request: authenticatedAIRequest(
            .aiShortcut(shortcut: shortcut.apiName, mailbox: mailbox),
            method: .post,
            parameters: AIConversationRequest(messages: messages, output: output, engine: engine)
        ))
    }
}
