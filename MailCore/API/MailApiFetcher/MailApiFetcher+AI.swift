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

/// implementing `MailApiAIFetchable`
public extension MailApiFetcher {
    func aiCreateConversation(messages: [AIMessage], output: AIOutputFormat = .mail) async throws -> AIConversationResponse {
        try await perform(request: authenticatedRequest(
            .ai,
            method: .post,
            parameters: AIConversationRequest(messages: messages, output: output)
        )).data
    }

    func aiShortcut(contextId: String, shortcut: String) async throws -> AIShortcutResponse {
        try await perform(request: authenticatedRequest(.aiShortcut(contextId: contextId, shortcut: shortcut), method: .patch))
            .data
    }

    func aiShortcutAndRecreateConversation(shortcut: String, messages: [AIMessage],
                                           output: AIOutputFormat = .mail) async throws -> AIShortcutResponse {
        try await perform(request: authenticatedRequest(
            .aiShortcut(shortcut: shortcut),
            method: .post,
            parameters: AIConversationRequest(messages: messages, output: output)
        )).data
    }
}
