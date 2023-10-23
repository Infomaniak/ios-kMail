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
import MailCore
import MailResources
import SwiftUI

@MainActor
final class AIModel: ObservableObject {
    enum State {
        case prompt, proposition
    }

    enum ToolbarStyle {
        case loading, success, errorWithAnswers, errorWithoutAnswers
    }

    private static let displayableErrors: [MailApiError] = [.apiAIMaxSyntaxTokensReached, .apiAITooManyRequests]

    private let mailboxManager: MailboxManager

    @Published var conversation = [AIMessage]()
    @Published var isLoading = false
    @Published var contextId: String?
    @Published var error: MailError?

    @Published var isShowingPrompt = false
    @Published var isShowingProposition = false

    var lastMessage: String {
        return conversation.last?.content ?? ""
    }

    var hasProposedAnswers: Bool {
        return conversation.count > 1
    }

    var currentStyle: SelectableTextView.Style {
        if let error {
            return .error(withLoadingState: !hasProposedAnswers)
        } else if isLoading {
            return .loading
        } else {
            return .standard
        }
    }

    var toolbarStyle: ToolbarStyle {
        if isLoading {
            return .loading
        }
        if error != nil {
            return hasProposedAnswers ? .errorWithAnswers : .errorWithoutAnswers
        }
        return .success
    }

    init(mailboxManager: MailboxManager) {
        self.mailboxManager = mailboxManager
    }

    func displayView(_ state: AIModel.State) {
        isShowingPrompt = state == .prompt
        isShowingProposition = state == .proposition
    }

    func addInitialPrompt(_ prompt: String) {
        conversation.append(AIMessage(type: .user, content: prompt))
        isLoading = true
    }

    func createConversation() async {
        do {
            let response = try await mailboxManager.apiFetcher.aiCreateConversation(
                messages: conversation,
                mailbox: mailboxManager.mailbox
            )
            handleAIResponse(response)
        } catch {
            handleError(error)
        }
    }

    func resetConversation() {
        conversation = []
        isLoading = false
        error = nil
    }

    func executeShortcut(_ shortcut: AIShortcutAction) async {
        if shortcut == .edit {
            conversation.append(AIMessage(type: .assistant, content: MailResourcesStrings.Localizable.aiMenuEditRequest))
            isShowingProposition = false
            Task { @MainActor in
                self.isShowingPrompt = true
            }
        } else {
            guard let contextId else { return }
            isLoading = true
            do {
                let response = try await mailboxManager.apiFetcher.aiShortcut(
                    contextId: contextId,
                    shortcut: shortcut,
                    mailbox: mailboxManager.mailbox
                )
                handleAIResponse(response)
            } catch let error as MailApiError where error == .apiAIContextIdExpired {
                await executeShortcutAndRecreateConversation(shortcut)
            } catch {
                handleError(error)
            }
        }
    }

    func splitSubjectAndBody() -> (subject: String?, body: String) {
        guard let contentRegex = try? NSRegularExpression(pattern: Constants.aiRegex, options: .dotMatchesLineSeparators) else {
            return (nil, lastMessage)
        }

        let messageRange = NSRange(lastMessage.startIndex ..< lastMessage.endIndex, in: lastMessage)
        guard let result = contentRegex.firstMatch(in: lastMessage, range: messageRange) else {
            return (nil, lastMessage)
        }

        guard let subjectRange = Range(result.range(withName: "subject"), in: lastMessage),
              let contentRange = Range(result.range(withName: "content"), in: lastMessage) else {
            return (nil, lastMessage)
        }

        let subject = lastMessage[subjectRange].trimmingCharacters(in: .whitespacesAndNewlines)
        let content = String(lastMessage[contentRange])
        return (subject, content)
    }

    private func executeShortcutAndRecreateConversation(_ shortcut: AIShortcutAction) async {
        do {
            let response = try await mailboxManager.apiFetcher.aiShortcutAndRecreateConversation(
                shortcut: shortcut,
                messages: conversation, mailbox: mailboxManager.mailbox
            )
            handleAIResponse(response)
        } catch {
            handleError(error)
        }
    }

    private func handleAIResponse(_ response: AIResponse) {
        if let newContextId = response.contextId {
            contextId = newContextId
        }

        if let shortcutResponse = response as? AIShortcutResponse {
            conversation.append(shortcutResponse.action)
        }
        conversation.append(AIMessage(type: .assistant, content: response.content))
        isLoading = false
    }

    private func handleError(_ error: Error) {
        isLoading = false

        if let mailApiError = error as? MailApiError, Self.displayableErrors.contains(mailApiError) {
            self.error = mailApiError
        } else {
            self.error = .unknownError
        }
    }
}
