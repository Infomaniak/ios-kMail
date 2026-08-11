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
import MailResources

// MARK: - Entity

@available(iOS 18.0, *)
@AppEntity(schema: .mail.draft)
struct MailDraftEntity: IndexedEntity {
    // MARK: Static

    static let defaultQuery = MailDraftEntityQuery()

    // MARK: Properties

    let id: String

    var to: [IntentPerson]
    var cc: [IntentPerson]
    var bcc: [IntentPerson]
    var subject: String?
    var body: AttributedString?
    var attachments: [IntentFile]
    var account: MailAccountEntity

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(MailResourcesStrings.Localizable.subjectTitle) \(subject ?? "")",
            subtitle: "\(MailResourcesStrings.Localizable.fromTitle) \(account.emailAddress)"
        )
    }

    init(
        id: String,
        to: [IntentPerson],
        cc: [IntentPerson],
        bcc: [IntentPerson],
        subject: String? = nil,
        body: AttributedString? = nil,
        attachments: [IntentFile],
        account: MailAccountEntity
    ) {
        self.id = id
        self.to = to
        self.cc = cc
        self.bcc = bcc
        self.subject = subject
        self.body = body
        self.attachments = attachments
        self.account = account
    }

    // MARK: Query

    struct MailDraftEntityQuery: EntityQuery {
        func entities(for identifiers: [MailDraftEntity.ID]) async throws -> [MailDraftEntity] {
            @InjectService var mailboxInfosManager: MailboxInfosManager
            @InjectService var accountManager: AccountManager

            let mailboxes = mailboxInfosManager.getMailboxes()
            return mailboxes.flatMap { mailbox -> [MailDraftEntity] in
                guard let mailboxManager = accountManager.getMailboxManager(for: mailbox) else {
                    return []
                }

                let drafts = mailboxManager.fetchResults(ofType: Draft.self) { $0 }.filter { identifiers.contains($0.localUUID) }
                return drafts.map { Self.mapDraft($0, mailbox: mailbox) }
            }
        }

        func suggestedEntities() async throws -> [MailDraftEntity] {
            @InjectService var mailboxInfosManager: MailboxInfosManager
            @InjectService var accountManager: AccountManager

            let mailboxes = mailboxInfosManager.getMailboxes()
            return mailboxes.flatMap { mailbox -> [MailDraftEntity] in
                guard let mailboxManager = accountManager.getMailboxManager(for: mailbox),
                      mailboxManager.getFolder(with: .draft) != nil
                else {
                    return []
                }

                let drafts = mailboxManager.fetchResults(ofType: Draft.self) { $0 }
                return Array(drafts.prefix(10)).map { MailAppIntentsHelper.mapDraft($0, mailbox: mailbox) }
            }
        }
    }
}
