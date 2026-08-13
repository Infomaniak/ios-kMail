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
import CoreSpotlight
import InfomaniakDI
import MailResources

@available(iOS 18.4, *)
@AppEntity(schema: .mail.message)
public struct MailMessageEntity: IndexedEntity {
    // MARK: Static

    public static let defaultQuery = MailMessageEntityQuery()

    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Message")
    }

    // MARK: Properties

    public let id: String

    public var to: [IntentPerson]
    public var cc: [IntentPerson]
    public var bcc: [IntentPerson]

    @Property(indexingKey: \.subject)
    public var subject: String?

    @Property(indexingKey: \.textContent)
    public var body: AttributedString?

    @Property(indexingKey: \.textContentSummary)
    public var preview: String

    public var attachments: [IntentFile]
    public var sender: IntentPerson
    public var dateSent: Date
    public var dateReceived: Date
    public var isRead: Bool
    public var isJunk: Bool
    public var isFlagged: Bool
    public var category: MailCategory?
    public var account: MailAccountEntity
    public var mailbox: MailboxEntity

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(subject ?? "")",
            subtitle: "\(mailbox.name)"
        )
    }

    public var hideInSpotlight: Bool {
        return false
    }

    public var attributeSet: CSSearchableItemAttributeSet {
        let set = CSSearchableItemAttributeSet(contentType: .emailMessage)

        let senderName: String = {
            if case .displayName(let name) = sender.name, !name.isEmpty {
                return name
            }
            if case .emailAddress(let email) = sender.handle?.value {
                return email
            }
            return ""
        }()
        set.displayName = senderName
        set.authorNames = [senderName]
        if case .emailAddress(let email) = sender.handle?.value {
            set.authorEmailAddresses = [email]
        }

        set.title = subject
        set.subject = subject

        set.contentDescription = preview
        set.textContent = preview

        set.contentCreationDate = dateReceived
        set.contentModificationDate = dateSent
        set.mailboxIdentifiers = [mailbox.name]
        set.accountIdentifier = account.id

        return set
    }

    public init(
        id: String,
        to: [IntentPerson],
        cc: [IntentPerson],
        bcc: [IntentPerson],
        subject: String? = nil,
        body: AttributedString? = nil,
        preview: String,
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
        self.preview = preview
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

    public init(from message: Message, mailbox: Mailbox) {
        self = MailAppIntentsHelper.mapMessage(message, mailbox: mailbox)
    }

    // MARK: Query

    public struct MailMessageEntityQuery: EntityStringQuery {
        public init() {}

        public func entities(for identifiers: [MailMessageEntity.ID]) async throws -> [MailMessageEntity] {
            @InjectService var mailboxInfosManager: MailboxInfosManager
            @InjectService var accountManager: AccountManager

            let mailboxes = mailboxInfosManager.getMailboxes()
            return mailboxes.flatMap { mailbox -> [MailMessageEntity] in
                guard let mailboxManager = accountManager.getMailboxManager(for: mailbox) else {
                    return []
                }

                let messages = mailboxManager.fetchResults(ofType: Message.self) {
                    $0.filter(NSPredicate(format: "uid IN %@", identifiers))
                }
                return messages.map { MailAppIntentsHelper.mapMessage($0, mailbox: mailbox) }
            }
        }

        public func suggestedEntities() async throws -> [MailMessageEntity] {
            @InjectService var mailboxInfosManager: MailboxInfosManager
            @InjectService var accountManager: AccountManager

            let mailboxes = mailboxInfosManager.getMailboxes()
            return mailboxes.flatMap { mailbox -> [MailMessageEntity] in
                guard let mailboxManager = accountManager.getMailboxManager(for: mailbox),
                      let folder = mailboxManager.getFolder(with: .inbox)
                else {
                    return []
                }

                let sortedMessages = folder.messages.sorted(by: \.date, ascending: false)
                return Array(sortedMessages.prefix(10)).map { MailAppIntentsHelper.mapMessage($0, mailbox: mailbox) }
            }
        }

        public func entities(matching query: String) async throws -> [MailMessageEntity] {
            @InjectService var mailboxInfosManager: MailboxInfosManager
            @InjectService var accountManager: AccountManager

            let mailboxes = mailboxInfosManager.getMailboxes()
            return mailboxes.flatMap { mailbox -> [MailMessageEntity] in
                guard let mailboxManager = accountManager.getMailboxManager(for: mailbox) else { return [] }

                let messages = mailboxManager.fetchResults(ofType: Message.self) {
                    $0.filter(NSPredicate(format: "subject CONTAINS[cd] %@ OR preview CONTAINS[cd] %@", query, query))
                }

                return Array(messages.prefix(10)).map { MailAppIntentsHelper.mapMessage($0, mailbox: mailbox) }
            }
        }
    }
}

// MARK: - Category enum

@available(iOS 18.0, *)
@AppEnum(schema: .mail.category)
public enum MailCategory: String, Sendable {
    case `default`

    public static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        `default`: "default"
    ]
}
