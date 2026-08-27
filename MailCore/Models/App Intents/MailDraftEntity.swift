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
import MailResources

@available(iOS 18.4, *)
@AppEntity(schema: .mail.draft)
public struct MailDraftEntity: IndexedEntity {
    public struct Identifier: Hashable, Sendable, EntityIdentifierConvertible {
        public let mailboxId: String
        public let draftId: String

        public var entityIdentifierString: String {
            "\(mailboxId)-\(draftId)"
        }

        public init(mailboxId: String, draftId: String) {
            self.mailboxId = mailboxId
            self.draftId = draftId
        }

        public static func entityIdentifier(for entityIdentifierString: String) -> Identifier? {
            let components = entityIdentifierString.split(separator: "-", maxSplits: 1)
            guard components.count == 2 else {
                return nil
            }

            return Identifier(
                mailboxId: String(components[0]),
                draftId: String(components[1])
            )
        }
    }

    // MARK: Static

    public static let defaultQuery = MailDraftEntityQuery()

    // MARK: Properties

    public let id: Identifier

    public var to: [IntentPerson]
    public var cc: [IntentPerson]
    public var bcc: [IntentPerson]
    public var subject: String?
    public var body: AttributedString?
    public var attachments: [IntentFile]
    public var account: MailAccountEntity

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(MailResourcesStrings.Localizable.subjectTitle) \(subject ?? "")",
            subtitle: "\(MailResourcesStrings.Localizable.fromTitle) \(account.emailAddress)"
        )
    }

    public init(
        id: Identifier,
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

    public struct MailDraftEntityQuery: EntityStringQuery {
        public init() {}

        public func entities(for identifiers: [MailDraftEntity.ID]) async throws -> [MailDraftEntity] {
            @InjectService var mailboxInfosManager: MailboxInfosManager
            @InjectService var accountManager: AccountManager

            return identifiers.compactMap {
                guard let mailbox = mailboxInfosManager.getMailbox(objectId: $0.mailboxId),
                      let mailboxManager = accountManager.getMailboxManager(for: mailbox),
                      let draft = mailboxManager.fetchObject(ofType: Draft.self, forPrimaryKey: $0.draftId) else {
                    return nil
                }

                return MailDraftEntity(draft: draft, mailbox: mailbox)
            }
        }

        public func suggestedEntities() async throws -> [MailDraftEntity] {
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
                return Array(drafts.prefix(10)).map { MailDraftEntity(draft: $0, mailbox: mailbox) }
            }
        }

        public func entities(matching query: String) async throws -> [MailDraftEntity] {
            @InjectService var mailboxInfosManager: MailboxInfosManager
            @InjectService var accountManager: AccountManager

            let mailboxes = mailboxInfosManager.getMailboxes()

            return mailboxes.flatMap { mailbox -> [MailDraftEntity] in
                guard let mailboxManager = accountManager.getMailboxManager(for: mailbox) else { return [] }

                let drafts = mailboxManager.fetchResults(ofType: Draft.self) {
                    $0.filter(NSPredicate(format: "subject CONTAINS[cd] %@", query))
                }

                return Array(drafts.prefix(10)).map { MailDraftEntity(draft: $0, mailbox: mailbox) }
            }
        }
    }
}

@available(iOS 18.4, *)
extension MailDraftEntity {
    init(draft: Draft, mailbox: Mailbox) {
        id = .init(mailboxId: mailbox.objectId, draftId: draft.localUUID)
        to = draft.to.map { IntentPerson(recipient: $0) }
        cc = draft.cc.map { IntentPerson(recipient: $0) }
        bcc = draft.bcc.map { IntentPerson(recipient: $0) }
        subject = draft.subject
        body = MailAppIntentsHelper.htmlToAttributedString(draft.body)
        attachments = []
        account = MailAccountEntity(mailbox: mailbox)
    }
}
