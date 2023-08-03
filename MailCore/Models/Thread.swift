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
import Sentry

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
    @Persisted public var messages: List<Message>
    @Persisted public var unseenMessages: Int
    @Persisted public var from: List<Recipient>
    @Persisted public var to: List<Recipient>
    @Persisted public var subject: String?
    @Persisted(indexed: true) public var date: Date
    @Persisted public var hasAttachments: Bool
    @Persisted public var hasDrafts: Bool
    @Persisted public var flagged: Bool
    @Persisted public var answered: Bool
    @Persisted public var forwarded: Bool
    @Persisted(originProperty: "threads") private var folders: LinkingObjects<Folder>
    @Persisted public var fromSearch = false

    @Persisted public var isUniqueThread = false

    @Persisted public var isDraft = false

    @Persisted public var duplicates = List<Message>()
    @Persisted public var messageIds: MutableSet<String>

    public var id: String {
        return uid
    }

    public var folder: Folder? {
        return folders.first
    }

    public var messageInFolderCount: Int {
        guard !fromSearch else { return 1 }
        return messages.filter { $0.folderId == self.folder?.id }.count
    }

    public var lastMessageFromFolder: Message? {
        messages.last { $0.folderId == folder?.id }
    }

    public var formattedSubject: String {
        guard let subject, !subject.isEmpty else {
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

    public func recomputeOrFail() throws {
        messageIds = messages.flatMap(\.linkedUids).toRealmSet()
        updateUnseenMessages()
        from = messages.flatMap { $0.from.detached() }.toRealmList()
        hasAttachments = messages.contains { $0.hasAttachments }
        hasDrafts = messages.map(\.isDraft).contains(true)
        updateFlagged()
        answered = messages.map(\.answered).contains(true)
        forwarded = messages.map(\.forwarded).contains(true)

        messages = messages.sorted {
            $0.date.compare($1.date) == .orderedAscending
        }.toRealmList()

        if let lastMessageFromFolderDate = lastMessageFromFolder?.date {
            date = lastMessageFromFolderDate
        } else {
            throw MailError.incoherentThreadDate
        }

        subject = messages.first?.subject
    }

    func addMessageIfNeeded(newMessage: Message) {
        messageIds.insert(objectsIn: newMessage.linkedUids)

        let folderRole = folder?.role

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
        let isTwinTheRealMessage = twinMessage.folderId == folder?.id
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

    public func lastMessageToExecuteAction(currentMailboxEmail: String) -> Message? {
        if let message = messages
            .last(where: { $0.isDraft == false && $0.fromMe(currentMailboxEmail: currentMailboxEmail) == false }) {
            return message
        } else if let message = messages.last(where: { $0.isDraft == false }) {
            return message
        }
        return messages.last
    }

    public func lastMessageAndItsDuplicateToExecuteAction(currentMailboxEmail: String) -> [Message] {
        guard let lastMessage = lastMessageToExecuteAction(currentMailboxEmail: currentMailboxEmail) else { return [] }
        var messageAndDuplicates = [lastMessage]
        messageAndDuplicates.append(contentsOf: lastMessage.duplicates)
        return messageAndDuplicates
    }

    private enum CodingKeys: String, CodingKey {
        case uid
        case messages
        case unseenMessages
        case from
        case to
        case subject
        case date
        case hasAttachments
        case hasDrafts
        case flagged
        case answered
        case forwarded
    }

    public convenience init(
        uid: String,
        messages: [Message],
        unseenMessages: Int,
        from: [Recipient],
        to: [Recipient],
        subject: String? = nil,
        date: Date,
        hasAttachments: Bool,
        hasDrafts: Bool,
        flagged: Bool,
        answered: Bool,
        forwarded: Bool
    ) {
        self.init()

        self.uid = uid
        self.messages = messages.toRealmList()
        self.unseenMessages = unseenMessages
        self.from = from.toRealmList()
        self.to = to.toRealmList()
        self.subject = subject
        self.date = date
        self.hasAttachments = hasAttachments
        self.hasDrafts = hasDrafts
        self.flagged = flagged
        self.answered = answered
        self.forwarded = forwarded
    }
}

public enum Filter: String {
    case all, seen, unseen, starred, unstarred

    public var predicate: String? {
        switch self {
        case .all:
            return nil
        case .seen:
            return "unseenMessages == 0"
        case .unseen:
            return "unseenMessages > 0"
        case .starred:
            return "flagged == TRUE"
        case .unstarred:
            return "flagged == FALSE"
        }
    }

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
