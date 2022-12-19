/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import MailResources
import RealmSwift

public struct ThreadResult: Decodable {
    public let threads: [Thread]?
    public let totalMessagesCount: Int
    public let messagesCount: Int
    public let currentOffset: Int
    public let threadMode: String
    public let folderUnseenMessages: Int
    public let resourcePrevious: String?
    public let resourceNext: String?
}

public class Thread: Object, Decodable, Identifiable {
    @Persisted(primaryKey: true) public var uid: String
    @Persisted public var messagesCount: Int
    @Persisted public var deletedMessagesCount: Int
    @Persisted public var messages: List<Message>
    @Persisted public var unseenMessages: Int
    @Persisted public var from: List<Recipient>
    @Persisted public var to: List<Recipient>
    @Persisted public var cc: List<Recipient>
    @Persisted public var bcc: List<Recipient>
    @Persisted public var subject: String?
    @Persisted public var date: Date
    @Persisted public var hasAttachments: Bool
    @Persisted public var hasStAttachments: Bool
    @Persisted public var hasDrafts: Bool
    @Persisted public var flagged: Bool
    @Persisted public var answered: Bool
    @Persisted public var forwarded: Bool
    @Persisted public var size: Int
    @Persisted(originProperty: "threads") public var parentLink: LinkingObjects<Folder>
    @Persisted public var fromSearch = false

    @Persisted public var messagePreviewed: Message?
    @Persisted public var isDraft = false

    @Persisted public var duplicates = List<Message>()
    @Persisted public var messageIds: MutableSet<String>
    @Persisted public var folderId: String

    public var id: String {
        return uid
    }

    public var parent: Folder? {
        return parentLink.first
    }

    public var formattedFrom: String {
        guard let from = from.last else { return MailResourcesStrings.Localizable.unknownRecipientTitle }
        return from.title
    }

    public var formattedTo: String {
        guard let to = to.last else { return MailResourcesStrings.Localizable.unknownRecipientTitle }
        return to.title
    }

    public var formattedSubject: String {
        guard let subject = subject, !subject.isEmpty else {
            return MailResourcesStrings.Localizable.noSubjectTitle
        }
        return subject
    }

    public var shouldPresentAsDraft: Bool {
        return messages.count == 1 && messages.first?.isDraft == true
    }

    public var hasUnseenMessages: Bool {
        unseenMessages > 0
    }

    public func updateUnseenMessages() {
        unseenMessages = messages.filter { !$0.seen }.count
    }

    public func updateFlagged() {
        flagged = messages.contains { $0.flagged }
    }

    public func recompute() {
        messageIds = messages.flatMap { $0.linkedUids }.toRealmSet()
        updateUnseenMessages()
        from = messages.flatMap { $0.from.detached() }.toRealmList()
        date = messages.last?.date ?? date
        size = messages.sum(of: \.size)
        hasAttachments = messages.contains { $0.hasAttachments }
        hasDrafts = messages.map { $0.isDraft }.contains(true)
        updateFlagged()
        answered = messages.map { $0.answered }.contains(true)
        forwarded = messages.map { $0.forwarded }.contains(true)
        messagesCount = messages.count

        messages = messages.sorted {
            $0.date.compare($1.date) == .orderedAscending
        }.toRealmList()
        messagePreviewed = messages.last { $0.folderId == folderId }
    }

    func addMessageIfNeeded(newMessage: Message) {
        messageIds.insert(objectsIn: newMessage.linkedUids)

        let folderRole = parent?.role

        // If the Message is deleted, but we are not in the Trash: ignore it, just leave.
        if folderRole != .trash && newMessage.inTrash { return }

        let shouldAddMessage: Bool
        switch folderRole {
        case .draft:
            shouldAddMessage = newMessage.isDraft
        case .trash:
            shouldAddMessage = newMessage.inTrash
        default:
            shouldAddMessage = true
        }

        if shouldAddMessage {
            if let twinMessage = messages.first(where: { $0.messageId == newMessage.messageId }) {
                addDuplicatedMessage(twinMessage: twinMessage, newMessage: newMessage)
            } else {
                messages.append(newMessage)
            }
        }
    }

    private func addDuplicatedMessage(twinMessage: Message, newMessage: Message) {
        let isTwinTheRealMessage = twinMessage.folderId == folderId
        if isTwinTheRealMessage {
            duplicates.append(newMessage)
        } else {
            if let index = messages.index(matching: { $0.messageId == twinMessage.messageId }) {
                messages.remove(at: index)
            }
            duplicates.append(twinMessage)
            messages.append(newMessage)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case uid
        case messagesCount
        case deletedMessagesCount
        case messages
        case unseenMessages
        case from
        case to
        case cc
        case bcc
        case subject
        case date
        case hasAttachments
        case hasStAttachments
        case hasDrafts
        case flagged
        case answered
        case forwarded
        case size
    }

    public convenience init(
        uid: String,
        messagesCount: Int,
        deletedMessagesCount: Int,
        messages: [Message],
        unseenMessages: Int,
        from: [Recipient],
        to: [Recipient],
        cc: [Recipient],
        bcc: [Recipient],
        subject: String? = nil,
        date: Date,
        hasAttachments: Bool,
        hasStAttachments: Bool,
        hasDrafts: Bool,
        flagged: Bool,
        answered: Bool,
        forwarded: Bool,
        size: Int,
        folderId: String = ""
    ) {
        self.init()

        self.uid = uid
        self.messagesCount = messagesCount
        self.deletedMessagesCount = deletedMessagesCount
        self.messages = messages.toRealmList()
        self.unseenMessages = unseenMessages
        self.from = from.toRealmList()
        self.to = to.toRealmList()
        self.cc = cc.toRealmList()
        self.bcc = bcc.toRealmList()
        self.subject = subject
        self.date = date
        self.hasAttachments = hasAttachments
        self.hasStAttachments = hasStAttachments
        self.hasDrafts = hasDrafts
        self.flagged = flagged
        self.answered = answered
        self.forwarded = forwarded
        self.size = size
        self.folderId = folderId
    }

    public convenience init(draft: Draft) {
        self.init()

        uid = draft.localUUID
        messagesCount = 1
        deletedMessagesCount = 0
        messages = [Message(draft: draft)].toRealmList()
        unseenMessages = 0
        to = draft.to.detached()
        cc = draft.cc.detached()
        bcc = draft.bcc.detached()
        subject = draft.subject
        date = draft.date
        hasAttachments = false
        hasStAttachments = false
        hasDrafts = true
        flagged = false
        answered = false
        forwarded = false
        size = 0
    }
}

public enum Filter: String {
    case all, seen, unseen, starred, unstarred

    public func accepts(thread: Thread) -> Bool {
        switch self {
        case .all:
            return true
        case .seen:
            return thread.unseenMessages == 0
        case .unseen:
            return thread.hasUnseenMessages
        case .starred:
            return thread.flagged
        case .unstarred:
            return !thread.flagged
        }
    }
}

public enum SearchCondition: Equatable {
    case filter(Filter)
    case from(String)
    case contains(String)
    case everywhere(Bool)
    case attachments(Bool)
}
