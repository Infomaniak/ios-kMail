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

extension IntentPerson {
    init(recipient: Recipient) {
        self.init(
            identifier: .applicationDefined(recipient.id),
            name: .displayName(recipient.name),
            handle: .init(emailAddress: recipient.email)
        )
    }

    var recipient: Recipient? {
        guard case .emailAddress(let email) = handle?.value else { return nil }

        switch name {
        case .displayName(let displayName):
            return Recipient(email: email, name: displayName)
        case .components(let components):
            return Recipient(email: email, name: components.formatted(.name(style: .long)))
        default:
            return Recipient(email: email, name: "Unknown")
        }
    }
}

@available(iOS 18.4, *)
public enum MailAppIntentsHelper {
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

        guard let message = mailboxManager.fetchObject(
            ofType: Message.self,
            forPrimaryKey: params.target.id.messageId
        ) else {
            return
        }

        let messageReply = MessageReply(frozenMessage: message.freezeIfNeeded(), replyMode: params.replyMode)
        let draft = Draft.replying(
            reply: messageReply,
            currentMailboxEmail: mailboxManager.mailbox.email,
            aliases: mailboxManager.mailbox.aliases.toArray()
        )

        let paramsTo = params.to.compactMap { $0.recipient }.toRealmList()
        if !paramsTo.isEmpty {
            draft.to = paramsTo
        }

        let paramsCc = params.cc.compactMap { $0.recipient }.toRealmList()
        if !paramsCc.isEmpty {
            draft.cc = paramsCc
        }

        let paramsBcc = params.bcc.compactMap { $0.recipient }.toRealmList()
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
}
