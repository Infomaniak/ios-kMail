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
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore

typealias ImageBase64AndMime = (imageEncoded: String, mimeType: String)

extension MessagesWorker {
    enum WorkerError: Error {
        case cantFetchMessage
    }
}

@MainActor
final class MessagesWorker: ObservableObject {
    @Published var presentableBodies = [String: PresentableBody]()

    private var replacedAllAttachments = [String: Bool]()
    private let bodyImageProcessor = BodyImageProcessor()
    private let mailboxManager: MailboxManager

    init(mailboxManager: MailboxManager) {
        self.mailboxManager = mailboxManager
    }

    func fetchAndProcessIfNeeded(messageUid: String) async throws {
        try await fetchMessageAndCalendar(of: messageUid, with: mailboxManager)
        guard !Task.isCancelled else { return }
        await prepareBodyAndAttachments(of: messageUid, with: mailboxManager)
    }
}

// MARK: - Fetch Message and Calendar Event

extension MessagesWorker {
    private func fetchMessageAndCalendar(of messageUid: String, with mailboxManager: MailboxManager) async throws {
        guard let message = getFrozenMessage(uid: messageUid, with: mailboxManager) else {
            return
        }

        try await fetchMessage(of: message, with: mailboxManager)
        await fetchEventCalendar(of: message, with: mailboxManager)
    }

    private func fetchMessage(of message: Message, with mailboxManager: MailboxManager) async throws {
        guard message.shouldComplete else {
            return
        }

        do {
            try await mailboxManager.message(message: message)
        } catch let error as ApiError where error.code == MailApiErrorCode.mailMessageNotFound  {
            @InjectService var snackbarPresenter: IKSnackBarPresentable
            snackbarPresenter.show(message: error.errorDescription ?? "")
            try? await mailboxManager.refreshFolder(from: [message], additionalFolder: nil)
        } catch {
            throw WorkerError.cantFetchMessage
        }
    }

    private func fetchEventCalendar(of message: Message, with mailboxManager: MailboxManager) async {
        try? await mailboxManager.calendarEvent(from: message.uid)
    }
}

// MARK: - Prepare body

extension MessagesWorker {
    private func prepareBodyAndAttachments(of messageUid: String, with mailboxManager: MailboxManager) async {
        guard let message = getFrozenMessage(uid: messageUid, with: mailboxManager) else {
            return
        }

        await prepareBody(of: message)
        guard !Task.isCancelled else { return }
        await insertInlineAttachments(for: message, with: mailboxManager)
    }

    private func prepareBody(of message: Message) async {
        guard !Task.isCancelled else { return }

        guard !hasPresentableBody(messageUid: message.uid),
              let updatedPresentableBody = await MessageBodyUtils.prepareWithPrintOption(message: message) else {
            return
        }

        setPresentableBody(updatedPresentableBody, for: message)
    }
}

// MARK: - Inline attachments

extension MessagesWorker {
    private func insertInlineAttachments(for frozenMessage: Message, with mailboxManager: MailboxManager) async {
        guard !Task.isCancelled else { return }

        guard !hasPresentableBodyWithAllAttachments(messageUid: frozenMessage.uid) else {
            return
        }

        let attachmentsArray = frozenMessage.attachments.filter { $0.contentId != nil }.toArray()
        guard !attachmentsArray.isEmpty else {
            return
        }

        let chunks = attachmentsArray.chunks(ofCount: Constants.inlineAttachmentBatchSize)
        for attachments in chunks {
            guard !Task.isCancelled else { return }
            let batchTask = Task {
                await processInlineAttachments(attachments, for: frozenMessage, with: mailboxManager)
            }
            await batchTask.finish()
        }

        setReplacedAllAttachments(for: frozenMessage)
    }

    private func processInlineAttachments(
        _ attachments: ArraySlice<Attachment>,
        for frozenMessage: Message,
        with mailboxManager: MailboxManager
    ) async {
        guard !Task.isCancelled else { return }

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

// MARK: - Utils

extension MessagesWorker {
    private func getFrozenMessage(uid: String, with mailboxManager: MailboxManager) -> Message? {
        return mailboxManager.transactionExecutor.fetchObject(ofType: Message.self, forPrimaryKey: uid)?.freeze()
    }

    private func setPresentableBody(_ presentableBody: PresentableBody, for message: Message) {
        presentableBodies[message.uid] = presentableBody
    }

    private func hasPresentableBody(messageUid: String) -> Bool {
        return presentableBodies[messageUid] != nil
    }

    private func setReplacedAllAttachments(for message: Message) {
        replacedAllAttachments[message.uid] = true
    }

    private func hasPresentableBodyWithAllAttachments(messageUid: String) -> Bool {
        return replacedAllAttachments[messageUid, default: false]
    }
}
