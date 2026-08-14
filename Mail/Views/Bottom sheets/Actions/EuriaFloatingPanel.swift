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
        message: Binding<Message?>,
        noReplyAlert: Binding<NoReplyAlertState?>,
        mailboxManager: MailboxManager,
        completionHandler: ((Action) -> Void)? = nil
    ) -> some View {
        modifier(
            EuriaFloatingPanel(
                message: message,
                noReplyAlert: noReplyAlert,
                mailboxManager: mailboxManager,
                completionHandler: completionHandler
            )
        )
    }
}

struct EuriaFloatingPanel: ViewModifier {
    @EnvironmentObject private var actionsProvider: ActionsProvider
    @EnvironmentObject private var mainViewState: MainViewState

    @State private var writerPanelState: AIWriterReplyPanelState?

    @StateObject private var aiModel: AIModel

    @Binding private var message: Message?
    @Binding private var noReplyAlert: NoReplyAlertState?

    let completionHandler: ((Action) -> Void)?
    let mailboxManager: MailboxManager

    private var origin: ActionOrigin {
        return .euriaActions(
            nearestNoReplyAlert: $noReplyAlert,
            nearestAIWriterReplyPanel: $writerPanelState,
            messageToProcessWithEuria: $message
        )
    }

    init(
        message: Binding<Message?>,
        noReplyAlert: Binding<NoReplyAlertState?>,
        mailboxManager: MailboxManager,
        completionHandler: ((Action) -> Void)? = nil
    ) {
        self.completionHandler = completionHandler
        _message = message
        _noReplyAlert = noReplyAlert
        self.mailboxManager = mailboxManager

        _aiModel = StateObject(wrappedValue: AIModel(
            mailboxManager: mailboxManager,
            draft: Draft(),
            isReplying: true
        ))
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: writerPanelState) { newValue in
                if newValue != nil {
                    aiModel.isShowingPrompt = true
                }
            }
            .mailFloatingPanel(item: $message, title: MailResourcesStrings.Localizable.askEuriaTitle) { message in
                VStack(alignment: .leading, spacing: 0) {
                    let availableActions = actionsProvider.actionsFor(origin: origin, messages: [message])
                    ForEach(availableActions) { action in
                        if action != availableActions.first {
                            IKDivider()
                        }

                        MessageActionView(
                            targetMessages: [message],
                            action: action,
                            origin: origin,
                            isMultipleSelection: false,
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
                    guard let replyingMessageUid = writerPanelState?.replyingMessageUid else { return }

                    mainViewState.composeMessageIntent = .replyingWithEuriaTo(
                        messageUid: replyingMessageUid,
                        replyMode: .reply,
                        replyBody: aiProposition,
                        originMailboxManager: mailboxManager
                    )
                }
            }
    }
}
