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

    @Published var conversation = [AIMessage]()
    @Published var isLoading = false
    @Published var error: AIError?

    @Published var isShowingPrompt = false
    @Published var isShowingProposition = false

    @Published var isShowingReplaceBodyAlert = false
    @Published var isShowingReplaceSubjectAlert: AIProposition?

    var keepConversationWhenPropositionIsDismissed = false

    private let mailboxManager: MailboxManager
    private let draftContentManager: DraftContentManager
    private let draft: Draft

    private var contextId: String?
    private var recipientsList: String?

    var lastMessage: String {
        return conversation.last?.content ?? ""
    }

    var assistantHasProposedAnswers: Bool {
        return conversation.contains { $0.type == .assistant }
    }

    var currentStyle: SelectableTextView.Style {
        if error != nil {
            return assistantHasProposedAnswers ? .error : .loadingError
        } else if isLoading {
            return .loading
        } else {
            return .standard
        }
    }

    var isReplying: Bool

    init(mailboxManager: MailboxManager, draftContentManager: DraftContentManager, draft: Draft, isReplying: Bool) {
        self.mailboxManager = mailboxManager
        self.draftContentManager = draftContentManager
        self.draft = draft
        self.isReplying = isReplying
    }
}

// MARK: - Manage conversation

extension AIModel {
    func addInitialPrompt(_ prompt: String) {
        recipientsList = getRecipientsList()
        conversation.append(AIMessage(type: .user, content: prompt, vars: AIMessageVars(recipient: recipientsList)))
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
        keepConversationWhenPropositionIsDismissed = false
        conversation = []
        isLoading = false
        error = nil
        recipientsList = nil
    }

    func executeShortcut(_ shortcut: AIShortcutAction) async {
        if shortcut == .edit {
            keepConversationWhenPropositionIsDismissed = true
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
        if replyingBody.type == .textPlain {
            replyingString = replyingBody.value
        } else if let value = replyingBody.value {
            let splitReply = await MessageBodyUtils.splitBodyAndQuote(messageBody: value)
            replyingString = try await SwiftSoupUtils(fromHTML: splitReply.messageBody).extractText()
        }

        guard let replyingString else { return }
        conversation.insert(
            AIMessage(type: .context, content: replyingString, vars: AIMessageVars(recipient: recipientsList)),
            at: 0
        )
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
        self.error = transformErrorToAIError(error)

        // If the context is too long, we must remove it so that the user can use
        // the AI assistant without context for future trials
        if self.error == .contextMaxSyntaxTokensReached {
            isReplying = false
        }
    }

    private func transformErrorToAIError(_ error: Error) -> AIError {
        guard let mailApiError = error as? MailApiError else { return .unknownError }

        switch mailApiError {
        case .apiAIMaxSyntaxTokensReached:
            if isReplying && !assistantHasProposedAnswers {
                return .contextMaxSyntaxTokensReached
            } else {
                return .maxSyntaxTokensReached
            }
        case .apiAITooManyRequests:
            return .tooManyRequests
        default:
            return .unknownError
        }
    }
}

// MARK: - Insert result

extension AIModel {
    func didTapInsert() async {
        let shouldReplaceBody = shouldOverrideBody()
        guard !shouldReplaceBody || UserDefaults.shared.doNotShowAIReplaceMessageAgain else {
            isShowingReplaceBodyAlert = true
            return
        }
        await splitPropositionAndInsert(shouldReplaceBody: shouldReplaceBody)
    }

    func splitPropositionAndInsert(shouldReplaceBody: Bool) async {
        let (subject, body) = splitSubjectAndBody()
        if let subject, !subject.isEmpty && shouldOverrideSubject() {
            isShowingReplaceSubjectAlert = AIProposition(subject: subject, body: body, shouldReplaceContent: shouldReplaceBody)
        } else {
            await insertProposition(subject: subject, body: body, shouldReplaceBody: shouldReplaceBody)
        }
    }

    func insertProposition(subject: String?, body: String, shouldReplaceBody: Bool) async {
        matomo.track(
            eventWithCategory: .aiWriter,
            action: .data,
            name: shouldReplaceBody ? "replaceProposition" : "insertProposition"
        )

        await draftContentManager.replaceContent(subject: subject, body: body)
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
        guard let result = contentRegex.firstMatch(in: lastMessage, range: messageRange) else { return (nil, lastMessage) }

        guard let subjectRange = Range(result.range(withName: "subject"), in: lastMessage),
              let contentRange = Range(result.range(withName: "content"), in: lastMessage) else {
            return (nil, lastMessage)
        }

        let subject = lastMessage[subjectRange].trimmingCharacters(in: .whitespacesAndNewlines)
        let content = String(lastMessage[contentRange])
        return (subject, content)
    }
}

// MARK: - Draft utils

extension AIModel {
    private func getLiveDraft() -> Draft? {
        return mailboxManager.getRealm().object(ofType: Draft.self, forPrimaryKey: draft.localUUID)
    }

    private func shouldOverrideSubject() -> Bool {
        guard let liveDraft = getLiveDraft() else { return false }
        return !liveDraft.subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func shouldOverrideBody() -> Bool {
        guard let liveDraft = getLiveDraft() else { return false }
        return !liveDraft.isEmptyOfUserChanges
    }

    private func getRecipientsList() -> String? {
        guard let liveDraft = getLiveDraft() else { return nil }

        let to: [String] = liveDraft.to.compactMap { recipient in
            guard !recipient.name.isEmpty else { return nil }
            return recipient.name
        }
        return to.isEmpty ? nil : to.joined(separator: ", ")
    }
}

// MARK: - AI Error

enum AIError: LocalizedError {
    case maxSyntaxTokensReached
    case contextMaxSyntaxTokensReached
    case tooManyRequests
    case unknownError

    var errorDescription: String? {
        switch self {
        case .maxSyntaxTokensReached:
            return MailResourcesStrings.Localizable.aiErrorMaxTokenReached
        case .contextMaxSyntaxTokensReached:
            return MailResourcesStrings.Localizable.aiErrorContextMaxTokenReached
        case .tooManyRequests:
            return MailResourcesStrings.Localizable.aiErrorTooManyRequests
        case .unknownError:
            return MailResourcesStrings.Localizable.aiErrorUnknown
        }
    }

    init(from error: Error) {
        guard let mailApiError = error as? MailApiError else {
            self = .unknownError
            return
        }

        switch mailApiError {
        case .apiAITooManyRequests:
            self = .tooManyRequests
        case .apiAIMaxSyntaxTokensReached:
            self = .maxSyntaxTokensReached
        default:
            self = .unknownError
        }
    }
}
