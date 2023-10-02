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

final class AIModel: ObservableObject {
    enum State {
        case prompt, proposition
    }

    private let mailboxManager: MailboxManager

    @Published var conversation = [AIMessage]()
    @Published var isLoading = false
    @Published var contextId: String?

    @Published var isShowingPrompt = false
    @Published var isShowingProposition = false

    init(mailboxManager: MailboxManager) {
        self.mailboxManager = mailboxManager
    }

    func displayView(_ state: AIModel.State) {
        isShowingPrompt = state == .prompt
        isShowingProposition = state == .proposition
    }

    @MainActor func createConversation() async {
        do {
            isLoading = true
            let result = try await mailboxManager.apiFetcher.aiCreateConversation(messages: conversation)

            withAnimation {
                isLoading = false
                conversation.append(AIMessage(type: .assistant, content: result.content))
                contextId = result.contextId
            }
        } catch {
            handleError(error)
        }
    }

    @MainActor func executeShortcut(_ shortcut: AIShortcutAction) async {
        switch shortcut {
        case .edit:
            conversation.append(AIMessage(type: .assistant, content: MailResourcesStrings.Localizable.aiMenuEditRequest))
            displayView(.prompt)
        default:
            guard let contextId else { return }
            isLoading = true
            do {
                let response = try await mailboxManager.apiFetcher.aiShortcut(contextId: contextId, shortcut: shortcut.apiName)
                conversation.append(contentsOf: [response.action, AIMessage(type: .assistant, content: response.content)])
                isLoading = false
            } catch let error as MailApiError where error == .apiAIContextIdExpired {
                await executeShortcutAndRecreateConversation(shortcut)
            } catch {
                handleError(error)
            }
        }
    }

    @MainActor private func executeShortcutAndRecreateConversation(_ shortcut: AIShortcutAction) async {
        do {
            let response = try await mailboxManager.apiFetcher.aiShortcut(shortcut: shortcut.apiName, messages: conversation)
            contextId = response.contextId
            conversation.append(contentsOf: [response.action, AIMessage(type: .assistant, content: response.content)])
            isLoading = false
        } catch {
            handleError(error)
        }
    }

    private func handleError(_ error: Error) {
        // TODO: Handle error (next PR)
    }
}
