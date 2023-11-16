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
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct AIProposition: Identifiable {
    let id = UUID()
    let subject: String
    let body: String
    let shouldReplaceContent: Bool
}

@MainActor
final class AIModel: ObservableObject {
    @LazyInjectService var matomo: MatomoUtils

    private static let displayableErrors: [MailApiError] = [.apiAIMaxSyntaxTokensReached, .apiAITooManyRequests]

    @Published var conversation = [AIMessage]()
    @Published var isLoading = false
    @Published var error: MailError?

    @Published var isShowingPrompt = false
    @Published var isShowingProposition = false

    @Published var isShowingReplaceBodyAlert = false
    @Published var isShowingReplaceSubjectAlert: AIProposition?

    private let mailboxManager: MailboxManager
    private let draftContentManager: DraftContentManager
    private var messageReply: MessageReply?
    private var contextId: String?

    var lastMessage: String {
        return conversation.last?.content ?? ""
    }

    var hasProposedAnswers: Bool {
        return conversation.count > 1
    }

    var currentStyle: SelectableTextView.Style {
        if error != nil {
            return hasProposedAnswers ? .error : .loadingError
        } else if isLoading {
            return .loading
        } else {
            return .standard
        }
    }

    var isReplying: Bool {
        messageReply?.isReplying == true
    }

    init(mailboxManager: MailboxManager, draftContentManager: DraftContentManager, messageReply: MessageReply?) {
        self.mailboxManager = mailboxManager
        self.draftContentManager = draftContentManager
        self.messageReply = messageReply
    }
}

// MARK: - Conversation

extension AIModel {
    func addInitialPrompt(_ prompt: String) {
        conversation.append(AIMessage(type: .user, content: prompt))
        isLoading = true
    }

    func createConversation() async {
        do {
            if isReplying {
                try await insertReplyingMessageInContext()
            }
            let response = try await mailboxManager.apiFetcher.aiCreateConversation(
                messages: conversation,
                engine: UserDefaults.shared.aiEngine,
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
                    engine: UserDefaults.shared.aiEngine,
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

    private func insertReplyingMessageInContext() async throws {
        guard let replyingBody = try await draftContentManager.getReplyingBody() else { return }

        var replyingString: String?
        if replyingBody.type == "plain/text" {
            replyingString = replyingBody.value
        } else if let value = replyingBody.value {
            let splitReply = await MessageBodyUtils.splitBodyAndQuote(messageBody: value)
            replyingString = try await SwiftSoupUtils.extractText(from: splitReply.messageBody)
        }

        guard let replyingString else { return }
        conversation.insert(AIMessage(type: .context, content: replyingString), at: 0)
    }

    private func executeShortcutAndRecreateConversation(_ shortcut: AIShortcutAction) async {
        do {
            let response = try await mailboxManager.apiFetcher.aiShortcutAndRecreateConversation(
                shortcut: shortcut,
                messages: conversation,
                engine: UserDefaults.shared.aiEngine,
                mailbox: mailboxManager.mailbox
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

// MARK: - Insert result

extension AIModel {
    func didTapInsert() {
        let shouldReplaceBody = draftContentManager.shouldOverrideBody()
        guard !shouldReplaceBody || UserDefaults.shared.doNotShowAIReplaceMessageAgain else {
            isShowingReplaceBodyAlert = true
            return
        }
        splitPropositionAndInsert(shouldReplaceBody: shouldReplaceBody)
    }

    func splitPropositionAndInsert(shouldReplaceBody: Bool) {
        let (subject, body) = splitSubjectAndBody()
        if let subject, !subject.isEmpty && draftContentManager.shouldOverrideSubject() {
            isShowingReplaceSubjectAlert = AIProposition(subject: subject, body: body, shouldReplaceContent: shouldReplaceBody)
        } else {
            insertProposition(subject: subject, body: body, shouldReplaceBody: shouldReplaceBody)
        }
    }

    func insertProposition(subject: String?, body: String, shouldReplaceBody: Bool) {
        matomo.track(
            eventWithCategory: .aiWriter,
            action: .data,
            name: shouldReplaceBody ? "replaceProposition" : "insertProposition"
        )

        draftContentManager.replaceContent(subject: subject, body: body)
        withAnimation {
            isShowingProposition = false
        }
    }

    private func splitSubjectAndBody() -> (subject: String?, body: String) {
        guard let contentRegex = try? NSRegularExpression(
            pattern: Constants.aiDetectPartsRegex,
            options: .dotMatchesLineSeparators
        ) else {
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
}
