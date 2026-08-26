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
import Foundation
import InfomaniakDI

// MARK: - Archive

@available(iOS 18.4, *)
@AppIntent(schema: .mail.archiveMail)
struct ArchiveMailIntent: AppIntent {
    var entities: [MailMessageEntity]

    func perform() async throws -> some IntentResult {
        try await MailMessageEntity.moveEntities(entities, to: .archive)
        return .result()
    }
}

// MARK: - Delete

@available(iOS 18.4, *)
@AppIntent(schema: .mail.deleteMail)
struct DeleteMailIntent: DeleteIntent {
    var entities: [MailMessageEntity]

    func perform() async throws -> some IntentResult {
        try await MailMessageEntity.moveEntities(entities, to: .trash)
        return .result()
    }
}

// MARK: - Forward

@available(iOS 18.4, *)
@AppIntent(schema: .mail.forwardMail)
struct ForwardMailIntent: AppIntent {
    var target: MailMessageEntity
    var to: [IntentPerson]
    var body: AttributedString?
    var cc: [IntentPerson]
    var bcc: [IntentPerson]
    var subject: String?
    var account: MailAccountEntity?
    var attachments: [IntentFile]

    func perform() async throws -> some IntentResult {
        @InjectService var mailboxInfosManager: MailboxInfosManager
        @InjectService var accountManager: AccountManager
        @InjectService var draftManager: DraftManager

        let (_, mailboxManager) = try MailAppIntentsHelper.resolveMailboxManager(
            mailboxId: target.id.mailboxId,
            mailboxInfosManager: mailboxInfosManager,
            accountManager: accountManager
        )

        try await MailAppIntentsHelper.performReplyOrForward(
            params: .init(
                mailboxManager: mailboxManager,
                target: target,
                replyMode: .forward,
                body: body,
                subject: subject,
                to: to,
                cc: cc,
                bcc: bcc,
                attachments: attachments
            ),
            draftManager: draftManager
        )

        return .result()
    }
}

// MARK: - Reply

@available(iOS 18.4, *)
@AppIntent(schema: .mail.replyMail)
struct ReplyMailIntent: AppIntent {
    var isReplyAll: Bool
    var target: MailMessageEntity
    var body: AttributedString?
    var subject: String?
    var account: MailAccountEntity?
    var attachments: [IntentFile]
    var to: [IntentPerson]
    var cc: [IntentPerson]
    var bcc: [IntentPerson]

    func perform() async throws -> some IntentResult {
        @InjectService var mailboxInfosManager: MailboxInfosManager
        @InjectService var accountManager: AccountManager
        @InjectService var draftManager: DraftManager

        let (_, mailboxManager) = try MailAppIntentsHelper.resolveMailboxManager(
            mailboxId: target.id.mailboxId,
            mailboxInfosManager: mailboxInfosManager,
            accountManager: accountManager
        )

        try await MailAppIntentsHelper.performReplyOrForward(
            params: .init(
                mailboxManager: mailboxManager,
                target: target,
                replyMode: isReplyAll ? .replyAll : .reply,
                body: body,
                subject: subject,
                to: to,
                cc: cc,
                bcc: bcc,
                attachments: attachments
            ),
            draftManager: draftManager
        )

        return .result()
    }
}

// MARK: - Update

@available(iOS 18.4, *)
@AppIntent(schema: .mail.updateMail)
struct UpdateMailIntent {
    var target: [MailMessageEntity]
    var isRead: Bool?
    var isFlagged: Bool?
    var isJunk: Bool?
    var mailbox: MailboxEntity?

    func perform() async throws -> some IntentResult {
        @InjectService var mailboxInfosManager: MailboxInfosManager
        @InjectService var accountManager: AccountManager

        for entity in target {
            guard let (_, mailboxManager) = try? MailAppIntentsHelper.resolveMailboxManager(
                mailboxId: entity.id.mailboxId,
                mailboxInfosManager: mailboxInfosManager,
                accountManager: accountManager
            ),
                let message = mailboxManager.fetchObject(ofType: Message.self, forPrimaryKey: entity.id.messageId)
            else {
                continue
            }

            let frozenMessage = message.freezeIfNeeded()

            if let isRead {
                try await mailboxManager.markAsSeen(message: frozenMessage, seen: isRead)
            }

            if let isFlagged {
                try await mailboxManager.star(messages: [frozenMessage], starred: isFlagged)
            }

            if let isJunk {
                let destination: FolderRole = isJunk ? .spam : .inbox
                _ = try await mailboxManager.move(messages: [frozenMessage], to: destination)
            }
        }

        return .result()
    }
}

// MARK: - Shared helpers

@available(iOS 18.4, *)
private extension MailMessageEntity {
    static func moveEntities(_ entities: [MailMessageEntity], to folderRole: FolderRole) async throws {
        @InjectService var mailboxInfosManager: MailboxInfosManager
        @InjectService var accountManager: AccountManager

        for entity in entities {
            guard let (_, mailboxManager) = try? MailAppIntentsHelper.resolveMailboxManager(
                mailboxId: entity.id.mailboxId,
                mailboxInfosManager: mailboxInfosManager,
                accountManager: accountManager
            ),
                let message = mailboxManager.fetchObject(ofType: Message.self, forPrimaryKey: entity.id.messageId)
            else {
                continue
            }

            _ = try await mailboxManager.move(messages: [message.freezeIfNeeded()], to: folderRole)
        }
    }
}
