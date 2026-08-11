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

// MARK: - Entity

@available(iOS 18.0, *)
@AppEntity(schema: .mail.message)
struct MailMessageEntity: IndexedEntity {
    // MARK: Static

    static let defaultQuery = MailMessageEntityQuery()

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Message")
    }

    // MARK: Properties

    let id: String

    var to: [IntentPerson]
    var cc: [IntentPerson]
    var bcc: [IntentPerson]
    var subject: String?
    var body: AttributedString?
    var attachments: [IntentFile]
    var sender: IntentPerson
    var dateSent: Date
    var dateReceived: Date
    var isRead: Bool
    var isJunk: Bool
    var isFlagged: Bool
    var category: MailCategory?
    var account: MailAccountEntity
    var mailbox: MailboxEntity

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(subject ?? "")",
            subtitle: "\(mailbox.name)"
        )
    }

    init(
        id: String,
        to: [IntentPerson],
        cc: [IntentPerson],
        bcc: [IntentPerson],
        subject: String? = nil,
        body: AttributedString? = nil,
        attachments: [IntentFile] = [],
        sender: IntentPerson,
        dateSent: Date,
        dateReceived: Date,
        isRead: Bool,
        isJunk: Bool,
        isFlagged: Bool,
        account: MailAccountEntity,
        mailbox: MailboxEntity
    ) {
        self.id = id
        self.to = to
        self.cc = cc
        self.bcc = bcc
        self.subject = subject
        self.body = body
        self.attachments = attachments
        self.sender = sender
        self.dateSent = dateSent
        self.dateReceived = dateReceived
        self.isRead = isRead
        self.isJunk = isJunk
        self.isFlagged = isFlagged
        self.account = account
        self.mailbox = mailbox
    }

    // MARK: Query

    struct MailMessageEntityQuery: EntityQuery {
        func entities(for identifiers: [MailMessageEntity.ID]) async throws -> [MailMessageEntity] {
            @InjectService var mailboxInfosManager: MailboxInfosManager
            @InjectService var accountManager: AccountManager

            let mailboxes = mailboxInfosManager.getMailboxes()
            return mailboxes.flatMap { mailbox -> [MailMessageEntity] in
                guard let mailboxManager = accountManager.getMailboxManager(for: mailbox) else {
                    return []
                }

                let messages = mailboxManager.fetchResults(ofType: Message.self) { $0 }.filter { identifiers.contains($0.uid) }
                return messages.map { Self.mapMessage($0, mailbox: mailbox) }
            }
        }

        func suggestedEntities() async throws -> [MailMessageEntity] {
            @InjectService var mailboxInfosManager: MailboxInfosManager
            @InjectService var accountManager: AccountManager

            let mailboxes = mailboxInfosManager.getMailboxes()
            return mailboxes.flatMap { mailbox -> [MailMessageEntity] in
                guard let mailboxManager = accountManager.getMailboxManager(for: mailbox),
                      let folder = mailboxManager.getFolder(with: .inbox)
                else {
                    return []
                }

                let messages = Array(folder.messages.sorted(by: \.date, ascending: false))
                return Array(messages.prefix(10)).map { MailAppIntentsHelper.mapMessage($0, mailbox: mailbox) }
            }
        }
    }
}

// MARK: - Category enum

@available(iOS 18.0, *)
@AppEnum(schema: .mail.category)
enum MailCategory: String {
    case `default`

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        `default`: "default"
    ]
}
