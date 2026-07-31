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

import InfomaniakCore
import MailCore
import MailCoreUI
import MailResources
import SwiftModalPresentation
import SwiftUI

extension View {
    func euriaFloatingPanel(
        messages: Binding<[Message]?>,
        noReplyAlert: Binding<NoReplyAlertState?>,
        mailboxManager: MailboxManager,
        completionHandler: ((Action) -> Void)? = nil
    ) -> some View {
        modifier(
            EuriaFloatingPanel(
                messages: messages,
                noReplyAlert: noReplyAlert,
                mailboxManager: mailboxManager,
                completionHandler: completionHandler
            )
        )
    }
}

struct EuriaFloatingPanel: ViewModifier {
    @EnvironmentObject private var actionsProvider: ActionsProvider
    @EnvironmentObject private var actionsManager: ActionsManager

    @State private var isShowingPanel = false

    @StateObject private var aiModel: AIModel

    @Binding var messages: [Message]?
    @Binding private var noReplyAlert: NoReplyAlertState?

    let completionHandler: ((Action) -> Void)?
    let mailboxManager: MailboxManager

    private var origin: ActionOrigin {
        return .euriaActions(nearestNoReplyAlert: $noReplyAlert, messagesToProcessWithEuria: $messages)
    }

    init(
        messages: Binding<[Message]?>,
        noReplyAlert: Binding<NoReplyAlertState?>,
        mailboxManager: MailboxManager,
        completionHandler: ((Action) -> Void)? = nil
    ) {
        self.completionHandler = completionHandler
        _messages = messages
        _noReplyAlert = noReplyAlert
        self.mailboxManager = mailboxManager

        let lastMessage = messages.wrappedValue?.lastMessageToExecuteAction(
            currentMailboxEmail: mailboxManager.mailbox.email,
            featureAvailableProvider: mailboxManager.featureAvailableProvider
        )
        var draft = Draft()

        if let lastMessage {
            let messageReply = MessageReply(frozenMessage: lastMessage.freeze(), replyMode: .reply)
            draft = Draft.replying(reply: messageReply, currentMailboxEmail: mailboxManager.mailbox.email)
        }

        let model = AIModel(mailboxManager: mailboxManager, draft: draft, isReplying: true)
        _aiModel = StateObject(wrappedValue: model)
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: messages) { newValue in
                isShowingPanel = newValue != nil && !availableActions(for: newValue).isEmpty

                if let newValue, let lastMessage = newValue.lastMessageToExecuteAction(
                    currentMailboxEmail: mailboxManager.mailbox.email,
                    featureAvailableProvider: mailboxManager.featureAvailableProvider
                ) {
                    let messageReply = MessageReply(frozenMessage: lastMessage.freeze(), replyMode: .reply)
                    aiModel.draftContentManager = DraftContentManager(
                        draftLocalUUID: UUID().uuidString,
                        messageReply: messageReply,
                        mailboxManager: mailboxManager
                    )
                } else if newValue == nil {
                    aiModel.draftContentManager = nil
                    aiModel.resetConversation()
                }
            }
            .onChange(of: isShowingPanel) { newValue in
                if !newValue {
                    clearMessagesIfPossible()
                }
            }
            .mailFloatingPanel(isPresented: $isShowingPanel, title: MailResourcesStrings.Localizable.askEuriaTitle) {
                VStack(alignment: .leading, spacing: 0) {
                    let availableActions = availableActions(for: messages)

                    ForEach(availableActions) { action in
                        if action != availableActions.first {
                            IKDivider()
                        }

                        MessageActionView(
                            aiModel: aiModel,
                            noReplyAlert: $noReplyAlert,
                            targetMessages: messages ?? [],
                            action: action,
                            origin: origin,
                            isMultipleSelection: (messages ?? []).count > 1,
                            completionHandler: completionHandler
                        )
                    }
                }
            }
            .aiPromptPresenter(isPresented: $aiModel.isShowingPrompt) {
                AIPromptView(aiModel: aiModel)
            }
            .sheet(isPresented: $aiModel.isShowingProposition) {
                AIPropositionView(aiModel: aiModel) { aiProposition in
                    let lastMessageToExecuteAction = messages?.lastMessageToExecuteAction(
                        currentMailboxEmail: mailboxManager.mailbox.email,
                        featureAvailableProvider: mailboxManager.featureAvailableProvider
                    )
                    guard let lastMessageToExecuteAction else { return }

                    let replyMode: ReplyMode = lastMessageToExecuteAction.canReplyAll(
                        currentMailboxEmail: mailboxManager.mailbox.email
                    ) ? .replyAll : .reply

                    actionsManager.composeMessageWithContent(
                        message: lastMessageToExecuteAction,
                        mode: replyMode,
                        content: aiProposition
                    )
                }
            }
    }

    private func availableActions(for messages: [Message]?) -> [Action] {
        guard let messages else { return [] }

        return actionsProvider.actionsFor(origin: origin, messages: messages)
    }

    private func clearMessagesIfPossible() {
        guard !isShowingPanel, !aiModel.isShowingPrompt, !aiModel.isShowingProposition else {
            return
        }

        messages = nil
    }
}
