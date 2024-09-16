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

    private let bodyImageProcessor = BodyImageProcessor()

    func fetchAndProcessIfNeeded(message: Message) async throws {
        guard presentableBodies[message.uid] == nil, let mailboxManager = accountManager.currentMailboxManager else {
            return
        }

        try await fetchMessageAndCalendar(of: message, with: mailboxManager)
        await prepareBody(of: message, with: mailboxManager)
    }
}

// MARK: - Fetch Message and Calendar Event

extension MessagesWorker {
    private func fetchMessageAndCalendar(of frozenMessage: Message, with mailboxManager: MailboxManager) async throws {
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
            .fetchObject(ofType: Message.self, forPrimaryKey: frozenMessage.uid)?.freeze(),
            let updatedPresentableBody = await MessageBodyUtils.prepareWithPrintOption(message: message) else {
            return
        }

        setPresentableBody(updatedPresentableBody, for: message)

        await insertInlineAttachments(for: message, with: mailboxManager)
    }

    private func setPresentableBody(_ presentableBody: PresentableBody, for message: Message) {
        presentableBodies[message.uid] = presentableBody
    }
}

// MARK: - Inline attachments

extension MessagesWorker {
    private func insertInlineAttachments(for frozenMessage: Message, with mailboxManager: MailboxManager) async {
        let attachmentsArray = frozenMessage.attachments.filter { $0.contentId != nil }.toArray()
        guard !attachmentsArray.isEmpty else {
            return
        }

        let chunks = attachmentsArray.chunks(ofCount: Constants.inlineAttachmentBatchSize)
        for attachments in chunks {
            let batchTask = Task {
                await processInlineAttachments(attachments, for: frozenMessage, with: mailboxManager)
            }
            await batchTask.finish()
        }
    }

    private func processInlineAttachments(
        _ attachments: ArraySlice<Attachment>,
        for frozenMessage: Message,
        with mailboxManager: MailboxManager
    ) async {
        guard let presentableBody = presentableBodies[frozenMessage.uid] else { return }

        let base64Images = await bodyImageProcessor.fetchBase64Images(attachments, mailboxManager: mailboxManager)

        async let mailBody = bodyImageProcessor.injectImagesInBody(
            body: presentableBody.body?.value,
            attachments: attachments,
            base64Images: base64Images
        )
        async let compactBody = bodyImageProcessor.injectImagesInBody(
            body: presentableBody.compactBody,
            attachments: attachments,
            base64Images: base64Images
        )

        let bodyValue = await mailBody
        let compactBodyCopy = await compactBody

        let body = presentableBody.body?.detached()
        body?.value = bodyValue

        let updatedPresentableBody = PresentableBody(
            body: body,
            compactBody: compactBodyCopy,
            quotes: presentableBody.quotes
        )

        setPresentableBody(updatedPresentableBody, for: frozenMessage)
    }
}
