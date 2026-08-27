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

// MARK: - Create Draft

@available(iOS 18.4, *)
@AppIntent(schema: .mail.createDraft)
struct CreateDraftIntent {
    var body: AttributedString?
    var to: [IntentPerson]
    var subject: String?
    var cc: [IntentPerson]
    var bcc: [IntentPerson]
    var account: MailAccountEntity?
    var attachments: [IntentFile]

    func perform() async throws -> some ReturnsValue<MailDraftEntity> {
        @InjectService var mailboxInfosManager: MailboxInfosManager
        @InjectService var accountManager: AccountManager
        @InjectService var draftManager: DraftManager

        let (mailbox, mailboxManager) = try MailAppIntentsHelper.resolveDefaultMailboxManager(
            account: account,
            mailboxInfosManager: mailboxInfosManager,
            accountManager: accountManager
        )

        let draft = Draft(
            subject: subject ?? "",
            body: "",
            to: to.compactMap { $0.recipient },
            cc: cc.compactMap { $0.recipient },
            bcc: bcc.compactMap { $0.recipient }
        )
        let draftUUID = draft.localUUID

        try mailboxManager.writeTransaction { realm in
            realm.add(draft, update: .modified)
        }

        try await MailAppIntentsHelper.setupDraftContent(
            draftUUID: draftUUID,
            body: body,
            subject: subject,
            attachments: attachments,
            mailboxManager: mailboxManager
        )

        try MailAppIntentsHelper.setDraftAction(.initialSave, draftUUID: draftUUID, mailboxManager: mailboxManager)
        await draftManager.syncDraft(mailboxManager: mailboxManager, showSnackbar: false)

        let accountEntity = MailAccountEntity(
            id: mailbox.objectId,
            name: mailbox.mailbox,
            emailAddress: mailbox.email
        )
        return .result(value: MailDraftEntity(
            id: .init(mailboxId: mailbox.objectId, draftId: draftUUID),
            to: to,
            cc: cc,
            bcc: bcc,
            subject: subject,
            body: body,
            attachments: attachments,
            account: accountEntity
        ))
    }
}

// MARK: - Update Draft

@available(iOS 18.4, *)
@AppIntent(schema: .mail.updateDraft)
struct UpdateDraftIntent {
    var target: MailDraftEntity
    var to: [IntentPerson]?
    var cc: [IntentPerson]?
    var bcc: [IntentPerson]?
    var subject: String?
    var body: AttributedString?
    var account: MailAccountEntity?
    var attachments: [IntentFile]?

    func perform() async throws -> some IntentResult {
        @InjectService var mailboxInfosManager: MailboxInfosManager
        @InjectService var accountManager: AccountManager
        @InjectService var draftManager: DraftManager

        let (_, mailboxManager) = try MailAppIntentsHelper.resolveMailboxManager(
            mailboxId: target.id.mailboxId,
            mailboxInfosManager: mailboxInfosManager,
            accountManager: accountManager
        )

        let draftUUID = target.id.draftId

        guard mailboxManager.fetchObject(ofType: Draft.self, forPrimaryKey: draftUUID) != nil else {
            throw MailError.unknownError
        }

        // Update recipients and subject
        try mailboxManager.writeTransaction { realm in
            guard let liveDraft = realm.object(ofType: Draft.self, forPrimaryKey: draftUUID) else { return }
            if let to {
                liveDraft.to = to.compactMap { $0.recipient }.toRealmList()
            }
            if let cc {
                liveDraft.cc = cc.compactMap { $0.recipient }.toRealmList()
            }
            if let bcc {
                liveDraft.bcc = bcc.compactMap { $0.recipient }.toRealmList()
            }
            if let subject {
                liveDraft.subject = subject
            }
        }

        // Update body and upload attachments
        if let body, let attachments {
            try await MailAppIntentsHelper.setupDraftContent(
                draftUUID: draftUUID,
                body: body,
                subject: subject,
                attachments: attachments,
                mailboxManager: mailboxManager
            )
        } else if let body {
            try await MailAppIntentsHelper.setupDraftContent(
                draftUUID: draftUUID,
                body: body,
                subject: subject,
                attachments: [],
                mailboxManager: mailboxManager
            )
        } else if let attachments, !attachments.isEmpty {
            await MailAppIntentsHelper.uploadAttachments(
                attachments,
                mailboxManager: mailboxManager,
                draftUUID: draftUUID
            )
        }

        try MailAppIntentsHelper.setDraftAction(.save, draftUUID: draftUUID, mailboxManager: mailboxManager)
        await draftManager.syncDraft(mailboxManager: mailboxManager, showSnackbar: false)

        return .result()
    }
}

// MARK: - Save Draft

@available(iOS 18.4, *)
@AppIntent(schema: .mail.saveDraft)
struct SaveDraftIntent {
    var target: MailDraftEntity

    func perform() async throws -> some IntentResult {
        @InjectService var mailboxInfosManager: MailboxInfosManager
        @InjectService var accountManager: AccountManager
        @InjectService var draftManager: DraftManager

        let (_, mailboxManager) = try MailAppIntentsHelper.resolveMailboxManager(
            mailboxId: target.id.mailboxId,
            mailboxInfosManager: mailboxInfosManager,
            accountManager: accountManager
        )

        let draftUUID = target.id.draftId

        guard mailboxManager.fetchObject(ofType: Draft.self, forPrimaryKey: draftUUID) != nil else {
            throw MailError.unknownError
        }

        try MailAppIntentsHelper.setDraftAction(.save, draftUUID: draftUUID, mailboxManager: mailboxManager)
        await draftManager.syncDraft(mailboxManager: mailboxManager, showSnackbar: false)

        return .result()
    }
}

// MARK: - Delete Draft

@available(iOS 18.4, *)
@AppIntent(schema: .mail.deleteDraft)
struct DeleteDraftIntent: DeleteIntent {
    var entities: [MailDraftEntity]

    func perform() async throws -> some IntentResult {
        @InjectService var mailboxInfosManager: MailboxInfosManager
        @InjectService var accountManager: AccountManager

        for entity in entities {
            guard let (_, mailboxManager) = try? MailAppIntentsHelper.resolveMailboxManager(
                mailboxId: entity.id.mailboxId,
                mailboxInfosManager: mailboxInfosManager,
                accountManager: accountManager
            ),
                let draft = mailboxManager.fetchObject(ofType: Draft.self, forPrimaryKey: entity.id.draftId)
            else {
                continue
            }

            try await mailboxManager.delete(draft: draft.freezeIfNeeded())
        }

        return .result()
    }
}

// MARK: - Send Draft

@available(iOS 18.4, *)
@AppIntent(schema: .mail.sendDraft)
struct SendDraftIntent {
    var target: MailDraftEntity
    var sendLaterDate: Date?

    func perform() async throws -> some IntentResult {
        @InjectService var mailboxInfosManager: MailboxInfosManager
        @InjectService var accountManager: AccountManager
        @InjectService var draftManager: DraftManager

        let (_, mailboxManager) = try MailAppIntentsHelper.resolveMailboxManager(
            mailboxId: target.id.mailboxId,
            mailboxInfosManager: mailboxInfosManager,
            accountManager: accountManager
        )

        let draftUUID = target.id.draftId

        guard mailboxManager.fetchObject(ofType: Draft.self, forPrimaryKey: draftUUID) != nil else {
            throw MailError.unknownError
        }

        if let sendLaterDate {
            try MailAppIntentsHelper.setDraftAction(
                .schedule,
                draftUUID: draftUUID,
                mailboxManager: mailboxManager,
                scheduleDate: sendLaterDate
            )
            await draftManager.syncDraft(mailboxManager: mailboxManager, showSnackbar: false)
        } else {
            try MailAppIntentsHelper.setDraftAction(.send, draftUUID: draftUUID, mailboxManager: mailboxManager)
            try await draftManager.sendDraft(localUUID: draftUUID, mailboxManager: mailboxManager)
        }

        return .result()
    }
}
