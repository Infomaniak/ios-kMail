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
import InfomaniakDI
import MailCore
import OSLog
import SwiftSoup

@available(iOS 18.4, *)
extension IntentFile: Attachable {
    public var suggestedName: String? {
        filename
    }

    public func writeToTemporaryURL() async throws -> (url: URL, title: String?) {
        let filenameWithExtension: String
        if let ext = type?.preferredFilenameExtension,
           !filename.capitalized.hasSuffix(".\(ext.capitalized)") {
            filenameWithExtension = "\(filename).\(ext)"
        } else {
            filenameWithExtension = filename
        }
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        let tempURL = temporaryDirectory.appendingPathComponent(URL(fileURLWithPath: filenameWithExtension).lastPathComponent)
        try data.write(to: tempURL, options: .atomic)
        return (tempURL, nil)
    }
}

@available(iOS 18.4, *)
final class NoOpAttachmentsDelegate: AttachmentsContentUpdatable {
    @MainActor func contentWillChange() {}
    @MainActor func handleGlobalError(_ error: MailError) {}
}

@available(iOS 18.4, *)
public enum MailAppIntentsHelper {
    public static func mapIntentPersonToRecipient(_ person: IntentPerson) -> Recipient? {
        guard case .emailAddress(let email) = person.handle?.value else { return nil }
        let name: String
        if case .displayName(let displayName) = person.name {
            name = displayName
        } else {
            name = ""
        }
        return Recipient(email: email, name: name)
    }

    public static func mapIntentPersonsToRecipients(_ persons: [IntentPerson]) -> [Recipient] {
        persons.compactMap { mapIntentPersonToRecipient($0) }
    }

    public static func mapRecipientToIntentPerson(_ recipient: Recipient) -> IntentPerson {
        IntentPerson(
            identifier: .applicationDefined(recipient.id),
            name: .displayName(recipient.name),
            handle: .init(emailAddress: recipient.email)
        )
    }

    public static func mapRecipientsToIntentPersons(_ recipients: [Recipient]) -> [IntentPerson] {
        recipients.map { mapRecipientToIntentPerson($0) }
    }

    public static func mapMessage(_ message: Message, mailbox: Mailbox) -> MailMessageEntity {
        let accountEntity = MailAccountEntity(
            id: mailbox.objectId,
            name: mailbox.mailbox,
            emailAddress: mailbox.email
        )
        let mailboxEntity = MailboxEntity(id: mailbox.objectId, name: mailbox.email, account: accountEntity)

        let sender: IntentPerson
        if let fromRecipient = message.from.first {
            sender = mapRecipientToIntentPerson(fromRecipient)
        } else {
            sender = IntentPerson(
                identifier: .applicationDefined("unknown"),
                name: .displayName(""),
                handle: .init(emailAddress: "")
            )
        }

        let bodyAttributedString = bodyToAttributedString(value: message.body?.value, type: message.body?.type)

        let messageId = "\(mailbox.objectId)-\(message.uid)"

        return MailMessageEntity(
            id: messageId,
            to: Array(message.to.map { MailAppIntentsHelper.mapRecipientToIntentPerson($0) }),
            cc: Array(message.cc.map { MailAppIntentsHelper.mapRecipientToIntentPerson($0) }),
            bcc: Array(message.bcc.map { MailAppIntentsHelper.mapRecipientToIntentPerson($0) }),
            subject: message.subject,
            body: bodyAttributedString,
            preview: message.preview,
            attachments: [],
            sender: sender,
            dateSent: message.internalDate,
            dateReceived: message.date,
            isRead: message.seen,
            isJunk: message.isSpam,
            isFlagged: message.flagged,
            account: accountEntity,
            mailbox: mailboxEntity
        )
    }

    public static func mapDraft(_ draft: Draft, mailbox: Mailbox) -> MailDraftEntity {
        let accountEntity = MailAccountEntity(
            id: mailbox.objectId,
            name: mailbox.mailbox,
            emailAddress: mailbox.email
        )

        let bodyAttributedString = htmlToAttributedString(draft.body)

        return MailDraftEntity(
            id: draft.localUUID,
            to: MailAppIntentsHelper.mapRecipientsToIntentPersons(draft.to.toArray()),
            cc: MailAppIntentsHelper.mapRecipientsToIntentPersons(draft.cc.toArray()),
            bcc: MailAppIntentsHelper.mapRecipientsToIntentPersons(draft.bcc.toArray()),
            subject: draft.subject,
            body: bodyAttributedString,
            attachments: [],
            account: accountEntity
        )
    }

    public static func mapMailbox(_ mailbox: Mailbox) -> MailboxEntity {
        MailboxEntity(
            id: mailbox.objectId,
            name: mailbox.email,
            account: MailAccountEntity(
                id: mailbox.objectId,
                name: mailbox.mailbox,
                emailAddress: mailbox.email
            )
        )
    }

    @available(iOS 27.0, *)
    public static func mapThread(_ thread: MailCore.Thread, mailbox: Mailbox) -> MailThreadEntity {
        let messagesEntities = Array(thread.messages.map { mapMessage($0, mailbox: mailbox) })
        return MailThreadEntity(id: thread.uid, title: thread.subject ?? "", messages: messagesEntities)
    }

    // MARK: Body conversion

    public static func bodyToAttributedString(value: String?, type: BodyType?) -> AttributedString? {
        guard let value else { return nil }
        switch type {
        case .textPlain:
            return try? AttributedString(markdown: value)
        case .textHtml, nil:
            return htmlToAttributedString(value)
        }
    }

    public static func htmlToAttributedString(_ html: String) -> AttributedString? {
        guard let document = try? SwiftSoup.parse(html),
              let body = document.body() else {
            return AttributedString(html)
        }
        let plainText = (try? body.text()) ?? html
        return try? AttributedString(markdown: plainText)
    }

    public static func attributedStringToHTML(_ attributedString: AttributedString) -> String {
        let plainText = String(attributedString.characters)
        let escaped = plainText
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        return escaped.replacingOccurrences(of: "\n", with: "<br>")
    }

    public static func resolveMailboxManager(
        mailboxId: String,
        mailboxInfosManager: MailboxInfosManager,
        accountManager: AccountManager
    ) throws -> (Mailbox, MailboxManager) {
        guard let mailbox = mailboxInfosManager.getMailbox(objectId: mailboxId),
              let mailboxManager = accountManager.getMailboxManager(for: mailbox)
        else {
            throw MailError.unknownError
        }
        return (mailbox, mailboxManager)
    }

    public static func resolveDefaultMailboxManager(
        account: MailAccountEntity?,
        mailboxInfosManager: MailboxInfosManager,
        accountManager: AccountManager
    ) throws -> (Mailbox, MailboxManager) {
        let mailboxId = account?.id
        if let mailboxId {
            return try resolveMailboxManager(
                mailboxId: mailboxId,
                mailboxInfosManager: mailboxInfosManager,
                accountManager: accountManager
            )
        }
        let mailboxes = mailboxInfosManager.getMailboxes()
        guard let mailbox = mailboxes.first(where: { $0.isPrimary }) ?? mailboxes.first,
              let mailboxManager = accountManager.getMailboxManager(for: mailbox)
        else {
            throw MailError.unknownError
        }
        return (mailbox, mailboxManager)
    }

    public static func setupDraftContent(
        draftUUID: String,
        body: AttributedString?,
        subject: String?,
        attachments: [IntentFile],
        mailboxManager: MailboxManager,
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

        let bodyText = body.map { attributedStringToHTML($0) } ?? ""
        await draftContentManager.replaceContent(
            subject: subject,
            body: bodyText,
            draftPrimaryKey: draftUUID
        )

        if !attachments.isEmpty {
            await uploadAttachments(
                attachments,
                mailboxManager: mailboxManager,
                draftUUID: draftUUID
            )
        }
    }

    public static func setDraftAction(
        _ action: SaveDraftOption,
        draftUUID: String,
        mailboxManager: MailboxManager,
        scheduleDate: Date? = nil
    ) throws {
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

    public static func uploadAttachments(
        _ intentFiles: [IntentFile],
        mailboxManager: MailboxManager,
        draftUUID: String
    ) async {
        let worker = AttachmentsManagerWorker(
            draftLocalUUID: draftUUID,
            mailboxManager: mailboxManager
        )
        worker.setUpdateDelegate(NoOpAttachmentsDelegate())

        guard let frozenDraft = mailboxManager
            .fetchObject(ofType: Draft.self, forPrimaryKey: draftUUID)?
            .freeze()
        else {
            Logger.general.error("Cannot upload attachments: draft \(draftUUID) not found")
            return
        }

        await worker.importAttachments(
            attachments: intentFiles,
            draft: frozenDraft,
            disposition: .attachment
        )
    }

    public struct ReplyForwardParams {
        public init(
            mailboxManager: MailboxManager,
            target: MailMessageEntity,
            replyMode: ReplyMode,
            body: AttributedString? = nil,
            subject: String? = nil,
            to: [IntentPerson],
            cc: [IntentPerson],
            bcc: [IntentPerson],
            attachments: [IntentFile]
        ) {
            self.mailboxManager = mailboxManager
            self.target = target
            self.replyMode = replyMode
            self.body = body
            self.subject = subject
            self.to = to
            self.cc = cc
            self.bcc = bcc
            self.attachments = attachments
        }

        var mailboxManager: MailboxManager
        var target: MailMessageEntity
        var replyMode: ReplyMode
        var body: AttributedString?
        var subject: String?
        var to: [IntentPerson]
        var cc: [IntentPerson]
        var bcc: [IntentPerson]
        var attachments: [IntentFile]
    }

    public static func performReplyOrForward(
        params: ReplyForwardParams,
        draftManager: DraftManager
    ) async throws {
        let mailboxManager = params.mailboxManager

        let message = try MailAppIntentsHelper.resolveMessage(
            params.target,
            mailboxManager: mailboxManager
        )

        let messageReply = MessageReply(frozenMessage: message.freezeIfNeeded(), replyMode: params.replyMode)
        let draft = Draft.replying(
            reply: messageReply,
            currentMailboxEmail: mailboxManager.mailbox.email,
            aliases: mailboxManager.mailbox.aliases.toArray()
        )

        let paramsTo = mapIntentPersonsToRecipients(params.to).toRealmList()
        if !paramsTo.isEmpty {
            draft.to = paramsTo
        }

        let paramsCc = mapIntentPersonsToRecipients(params.cc).toRealmList()
        if !paramsCc.isEmpty {
            draft.cc = paramsCc
        }

        let paramsBcc = mapIntentPersonsToRecipients(params.bcc).toRealmList()
        if !paramsBcc.isEmpty {
            draft.bcc = paramsBcc
        }

        let draftUUID = draft.localUUID
        let draftSubject = params.subject ?? draft.subject

        try mailboxManager.writeTransaction { realm in
            realm.add(draft, update: .modified)
        }

        try await setupDraftContent(
            draftUUID: draftUUID,
            body: params.body,
            subject: draftSubject,
            attachments: params.attachments,
            mailboxManager: mailboxManager,
            messageReply: messageReply
        )

        try setDraftAction(.send, draftUUID: draftUUID, mailboxManager: mailboxManager)
        try await draftManager.sendDraft(localUUID: draftUUID, mailboxManager: mailboxManager)
    }

    @available(iOS 18.4, *)
    public static func messageUID(
        from entityID: String,
        mailboxID: String
    ) -> String? {
        let prefix = "\(mailboxID)-"

        guard entityID.hasPrefix(prefix) else {
            return nil
        }

        let messageUID = String(entityID.dropFirst(prefix.count))
        return messageUID.isEmpty ? nil : messageUID
    }

    @available(iOS 18.4, *)
    public static func resolveMessage(
        _ entity: MailMessageEntity,
        mailboxManager: MailboxManager
    ) throws -> Message {
        guard let messageUID = messageUID(
            from: entity.id,
            mailboxID: entity.mailbox.id
        ),
            let message = mailboxManager.fetchObject(
                ofType: Message.self,
                forPrimaryKey: messageUID
            )
        else {
            throw MailError.localMessageNotFound
        }

        return message
    }
}
