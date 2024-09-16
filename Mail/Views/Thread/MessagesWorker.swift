/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import InfomaniakDI
import MailCore

extension MessagesWorker {
    enum WorkerError: Error {
        case cantFetchMessage
    }
}

@MainActor
final class MessagesWorker: ObservableObject {
    @LazyInjectService var accountManager: AccountManager
    @LazyInjectService private var snackbarPresenter: SnackBarPresentable

    @Published var presentableBodies = [String: PresentableBody]()

    private let messages = [Message]()

    func loadIfNeeded(message: Message) async throws {
        guard presentableBodies[message.uid] == nil, let mailboxManager = accountManager.currentMailboxManager else {
            return
        }

        try await loadMessageAndCalendar(of: message, with: mailboxManager)
        await prepareBody(of: message, with: mailboxManager)
    }
}

// MARK: - Fetch Message and Calendar event

extension MessagesWorker {
    private func loadMessageAndCalendar(of frozenMessage: Message, with mailboxManager: MailboxManager) async throws {
        async let fetchMessageResult: Void = fetchMessage(of: frozenMessage, with: mailboxManager)
        async let fetchEventCalendar: Void = fetchEventCalendar(of: frozenMessage, with: mailboxManager)

        try await fetchMessageResult
        await fetchEventCalendar
    }

    private func fetchMessage(of message: Message, with mailboxManager: MailboxManager) async throws {
        guard message.shouldComplete else {
            return
        }

        await tryOrDisplayError {
            do {
                try await mailboxManager.message(message: message)
            } catch let error as MailApiError where error == .apiMessageNotFound {
                snackbarPresenter.show(message: error.errorDescription ?? "")
                try? await mailboxManager.refreshFolder(from: [message], additionalFolder: nil)
            } catch let error as AFErrorWithContext where error.afError.isExplicitlyCancelledError {
                throw WorkerError.cantFetchMessage
            } catch {
                throw WorkerError.cantFetchMessage
            }
        }
    }

    private func fetchEventCalendar(of message: Message, with mailboxManager: MailboxManager) async {
        try? await mailboxManager.calendarEvent(from: message.uid)
    }
}

// MARK: - Prepare body

extension MessagesWorker {
    private func prepareBody(of frozenMessage: Message, with mailboxManager: MailboxManager) async {
        guard let message = mailboxManager.transactionExecutor
            .fetchObject(ofType: Message.self, forPrimaryKey: frozenMessage.uid)?.freezeIfNeeded(),
            let updatedPresentableBody = await MessageBodyUtils.prepareWithPrintOption(message: message) else {
            return
        }

        presentableBodies[message.uid] = updatedPresentableBody
    }
}
