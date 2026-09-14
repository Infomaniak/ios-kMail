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

import AppIntents
import Contacts
import CoreSpotlight
import InfomaniakDI
import OSLog
import SwiftSoup

@available(iOS 18.4, *)
struct AppIntentDraftContentHelper {
    let mailboxManager: MailboxManager

    func setupDraftContent(
        draftUUID: String,
        body: AttributedString?,
        subject: String?,
        attachments: [IntentFile],
        messageReply: MessageReply? = nil
    ) async throws {
        let draftContentManager = DraftContentManager(
            draftLocalUUID: draftUUID,
            messageReply: messageReply,
            mailboxManager: mailboxManager
        )

        if let frozenDraft = mailboxManager.fetchObject(ofType: Draft.self, forPrimaryKey: draftUUID)?.freeze() {
            _ = try await draftContentManager.prepareCompleteDraft(incompleteDraft: frozenDraft)
        }

        await draftContentManager.replaceContent(subject: subject, body: body?.htmlString ?? "", draftPrimaryKey: draftUUID)

        if !attachments.isEmpty {
            await uploadAttachments(attachments, draftUUID: draftUUID)
        }
    }

    func setDraftAction(_ action: SaveDraftOption, draftUUID: String, scheduleDate: Date? = nil) throws {
        try mailboxManager.writeTransaction { realm in
            guard let liveDraft = realm.object(ofType: Draft.self, forPrimaryKey: draftUUID) else { return }
            liveDraft.action = action
            switch action {
            case .send, .sendReaction:
                liveDraft.delay = UserDefaults.shared.cancelSendDelay.rawValue
            case .schedule:
                liveDraft.scheduleDate = scheduleDate
                liveDraft.delay = nil
            default:
                break
            }
        }
    }

    func uploadAttachments(_ intentFiles: [IntentFile], draftUUID: String) async {
        let worker = AttachmentsManagerWorker(draftLocalUUID: draftUUID, mailboxManager: mailboxManager)

        guard let frozenDraft = mailboxManager.fetchObject(ofType: Draft.self, forPrimaryKey: draftUUID)?.freeze() else {
            Logger.general.error("Cannot upload attachments: draft \(draftUUID) not found")
            return
        }

        await worker.importAttachments(
            attachments: intentFiles,
            draft: frozenDraft,
            disposition: .attachment
        )
    }

    func performReplyOrForward(draftManager: DraftManager, replyMode: ReplyMode, intent: ReplyForwardIntent) async throws {
        guard let message = mailboxManager.fetchObject(ofType: Message.self, forPrimaryKey: intent.target.id.messageId) else {
            return
        }

        let messageReply = MessageReply(frozenMessage: message.freezeIfNeeded(), replyMode: replyMode)
        let draft = Draft.replying(
            reply: messageReply,
            currentMailboxEmail: mailboxManager.mailbox.email,
            aliases: mailboxManager.mailbox.aliases.toArray()
        )

        let paramsTo = intent.to.compactMap { $0.recipient }.toRealmList()
        if !paramsTo.isEmpty {
            draft.to = paramsTo
        }

        let paramsCc = intent.cc.compactMap { $0.recipient }.toRealmList()
        if !paramsCc.isEmpty {
            draft.cc = paramsCc
        }

        let paramsBcc = intent.bcc.compactMap { $0.recipient }.toRealmList()
        if !paramsBcc.isEmpty {
            draft.bcc = paramsBcc
        }

        let draftUUID = draft.localUUID
        let draftSubject = intent.subject ?? draft.subject

        try mailboxManager.writeTransaction { realm in
            realm.add(draft, update: .modified)
        }

        try await setupDraftContent(
            draftUUID: draftUUID,
            body: intent.body,
            subject: draftSubject,
            attachments: intent.attachments,
            messageReply: messageReply
        )

        try setDraftAction(.send, draftUUID: draftUUID)
        try await draftManager.sendDraft(localUUID: draftUUID, mailboxManager: mailboxManager)
    }
}
