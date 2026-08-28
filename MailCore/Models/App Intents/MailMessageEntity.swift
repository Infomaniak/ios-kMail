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
import MailResources

@available(iOS 18.4, *)
@AppEntity(schema: .mail.message)
public struct MailMessageEntity: IndexedEntity {
    public struct Identifier: Hashable, Sendable, EntityIdentifierConvertible {
        public let mailboxId: String
        public let messageId: String

        public var entityIdentifierString: String {
            "\(mailboxId)-\(messageId)"
        }

        public init(mailboxId: String, messageId: String) {
            self.mailboxId = mailboxId
            self.messageId = messageId
        }

        public static func entityIdentifier(for entityIdentifierString: String) -> Identifier? {
            let components = entityIdentifierString.split(separator: "-", maxSplits: 1)
            guard components.count == 2 else {
                return nil
            }

            return Identifier(
                mailboxId: String(components[0]),
                messageId: String(components[1])
            )
        }
    }

    // MARK: Static

    public static let defaultQuery = MailMessageEntityQuery()

    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Message")
    }

    // MARK: Properties

    public let id: Identifier

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
            subtitle: "\(preview)"
        )
    }

    public var hideInSpotlight = false

    public var attributeSet: CSSearchableItemAttributeSet {
        let set = CSSearchableItemAttributeSet(contentType: .emailMessage)
        let recipients = to + cc + bcc

        set.displayName = subject ?? preview
        set.title = subject
        set.contentDescription = preview
        set.textContent = body.map { String($0.characters) } ?? preview

        set.authors = sender.searchablePerson.map { [$0] }
        set.primaryRecipients = to.compactMap(\.searchablePerson)
        set.additionalRecipients = cc.compactMap(\.searchablePerson)
        set.hiddenAdditionalRecipients = bcc.compactMap(\.searchablePerson)
        set.authorNames = sender.searchableName.map { [$0] }
        set.authorEmailAddresses = sender.emailAddress.map { [$0] }
        set.recipientNames = recipients.compactMap(\.searchableName)
        set.recipientEmailAddresses = recipients.compactMap(\.emailAddress)

        set.accountIdentifier = account.id
        set.accountHandles = [account.emailAddress]
        set.domainIdentifier = mailbox.id
        set.likelyJunk = NSNumber(value: isJunk)

        return set
    }

    public init(
        id: Identifier,
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

    // MARK: Query

    public struct MailMessageEntityQuery: EntityStringQuery {
        public init() {}

        public func entities(for identifiers: [MailMessageEntity.ID]) async throws -> [MailMessageEntity] {
            @InjectService var mailboxInfosManager: MailboxInfosManager
            @InjectService var accountManager: AccountManager

            return identifiers.compactMap {
                guard let mailbox = mailboxInfosManager.getMailbox(objectId: $0.mailboxId),
                      let mailboxManager = accountManager.getMailboxManager(for: mailbox),
                      let message = mailboxManager.fetchObject(ofType: Message.self, forPrimaryKey: $0.messageId) else {
                    return nil
                }

                return MailMessageEntity(message: message, mailbox: mailbox)
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
                return Array(sortedMessages.prefix(10)).map { MailMessageEntity(message: $0, mailbox: mailbox) }
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

                return Array(messages.prefix(10)).map { MailMessageEntity(message: $0, mailbox: mailbox) }
            }
        }
    }
}

@available(iOS 18.4, *)
extension MailMessageEntity {
    init(message: Message, mailbox: Mailbox) {
        let mailboxEntity = MailboxEntity(mailbox: mailbox)

        let sender: IntentPerson
        if let fromRecipient = message.from.first {
            sender = IntentPerson(recipient: fromRecipient)
        } else {
            sender = IntentPerson(
                identifier: .applicationDefined("unknown"),
                name: .displayName(""),
                handle: .init(emailAddress: "")
            )
        }

        id = .init(mailboxId: mailbox.objectId, messageId: message.uid)
        to = Array(message.to.map { IntentPerson(recipient: $0) })
        cc = Array(message.cc.map { IntentPerson(recipient: $0) })
        bcc = Array(message.bcc.map { IntentPerson(recipient: $0) })
        subject = message.formattedSubject
        body = AttributedString(body: message.body)
        preview = message.preview
        attachments = []
        self.sender = sender
        dateSent = message.internalDate
        dateReceived = message.date
        isRead = message.seen
        isJunk = message.isSpam
        isFlagged = message.flagged
        account = mailboxEntity.account
        self.mailbox = mailboxEntity
    }
}

// MARK: - Category enum

@available(iOS 18.0, *)
public enum MailCategory: String, Sendable {
    case `default`

    public static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        `default`: "default"
    ]
}
