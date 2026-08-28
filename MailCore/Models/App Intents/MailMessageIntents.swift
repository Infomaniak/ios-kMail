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
protocol ReplyForwardIntent {
    var target: MailMessageEntity { get }
    var body: AttributedString? { get }
    var subject: String? { get }
    var to: [IntentPerson] { get }
    var cc: [IntentPerson] { get }
    var bcc: [IntentPerson] { get }
    var attachments: [IntentFile] { get }
}

@available(iOS 18.4, *)
@AppIntent(schema: .mail.forwardMail)
struct ForwardMailIntent: AppIntent, ReplyForwardIntent {
    var target: MailMessageEntity
    var to: [IntentPerson]
    var body: AttributedString?
    var cc: [IntentPerson]
    var bcc: [IntentPerson]
    var subject: String?
    // periphery:ignore - Used by AppIntent macro
    var account: MailAccountEntity?
    var attachments: [IntentFile]

    func perform() async throws -> some IntentResult {
        @InjectService var accountManager: AccountManager
        @InjectService var draftManager: DraftManager

        guard let mailboxManager = accountManager.getMailboxManager(for: target.id.mailboxId) else {
            throw MailError.unknownError
        }

        let draftContentHelper = AppIntentDraftContentHelper(mailboxManager: mailboxManager)
        try await draftContentHelper.performReplyOrForward(draftManager: draftManager, replyMode: .forward, intent: self)

        return .result()
    }
}

// MARK: - Reply

@available(iOS 18.4, *)
@AppIntent(schema: .mail.replyMail)
struct ReplyMailIntent: AppIntent, ReplyForwardIntent {
    var isReplyAll: Bool
    var target: MailMessageEntity
    var body: AttributedString?
    var subject: String?
    // periphery:ignore - Used by AppIntent macro
    var account: MailAccountEntity?
    var attachments: [IntentFile]
    var to: [IntentPerson]
    var cc: [IntentPerson]
    var bcc: [IntentPerson]

    func perform() async throws -> some IntentResult {
        @InjectService var accountManager: AccountManager
        @InjectService var draftManager: DraftManager

        guard let mailboxManager = accountManager.getMailboxManager(for: target.id.mailboxId) else {
            throw MailError.unknownError
        }

        let draftContentHelper = AppIntentDraftContentHelper(mailboxManager: mailboxManager)
        try await draftContentHelper.performReplyOrForward(
            draftManager: draftManager,
            replyMode: isReplyAll ? .replyAll : .reply,
            intent: self
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
    // periphery:ignore - Used by AppIntent macro
    var mailbox: MailboxEntity?

    func perform() async throws -> some IntentResult {
        @InjectService var accountManager: AccountManager

        for entity in target {
            guard let mailboxManager = accountManager.getMailboxManager(for: entity.id.mailboxId),
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
        @InjectService var accountManager: AccountManager

        for entity in entities {
            guard let mailboxManager = accountManager.getMailboxManager(for: entity.id.mailboxId),
                  let message = mailboxManager.fetchObject(ofType: Message.self, forPrimaryKey: entity.id.messageId)
            else {
                continue
            }

            _ = try await mailboxManager.move(messages: [message.freezeIfNeeded()], to: folderRole)
        }
    }
}
