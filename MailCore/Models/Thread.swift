/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

/// A Thread has :
/// - One folder
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
    @Persisted public var lastAction: ThreadLastAction?
    @Persisted public var folderId = ""
    @Persisted(originProperty: "threads") private var folders: LinkingObjects<Folder>
    @Persisted public var fromSearch = false
    @Persisted public var searchFolderName: String?
    @Persisted public var bimi: Bimi?

    @Persisted public var isDraft = false

    @Persisted public var duplicates = List<Message>()
    @Persisted public var messageIds: MutableSet<String>

    @Persisted public var snoozeState: SnoozeState?
    @Persisted public var snoozeAction: String?
    @Persisted public var snoozeEndDate: Date?

    /// This property is used to remove threads from list before network call is finished
    @Persisted public var isMovedOutLocally = false

    public var id: String {
        return uid
    }

    /// Parent folder of the thread.
    /// (A thread only has one folder)
    public var folder: Folder? {
        return folders.first
    }

    public var messageInFolderCount: Int {
        guard !fromSearch else { return 1 }
        return messages.filter { $0.folderId == self.folderId }.count
    }

    public var lastMessageFromFolder: Message? {
        // Search should be excluded from folderId check.
        guard !fromSearch else {
            return messages.last
        }

        return messages.last { $0.folderId == folderId }
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

    public func makeFromSearch(using realm: Realm) {
        fromSearch = true
        guard messages.count == 1,
              let message = messages.first else {
            return
        }
        let parentFolder = realm.object(ofType: Folder.self, forPrimaryKey: message.folderId)
        searchFolderName = parentFolder?.localizedName
    }

    /// Re-generate `Thread` properties given the messages it contains.
    public func recomputeOrFail() throws {
        messageIds = messages.flatMap(\.linkedUids).toRealmSet()
        updateUnseenMessages()
        from = messages.flatMap { $0.from.detached() }.toRealmList()
        hasAttachments = messages.contains { $0.hasAttachments }
        hasDrafts = messages.map(\.isDraft).contains(true)
        updateFlagged()
        answered = messages.map(\.answered).contains(true)
        forwarded = messages.map(\.forwarded).contains(true)

        // Re-ordering of messages in a thread
        messages = messages.sorted {
            $0.date.compare($1.date) == .orderedAscending
        }.toRealmList()

        if let lastMessageFromFolderDate = lastMessageFromFolder?.date {
            date = lastMessageFromFolderDate
        } else {
            throw MailError.incoherentThreadDate
        }

        lastAction = getLastAction()

        subject = messages.first?.subject

        updateSnooze()
    }

    private func updateSnooze() {
        let messagesThatCanBeSnoozed = Array(messages) + Array(duplicates)
        let lastSnoozedMessage = messagesThatCanBeSnoozed.last {
            $0.snoozeState != nil && $0.snoozeAction != nil && $0.snoozeEndDate != nil
        }

        snoozeState = lastSnoozedMessage?.snoozeState
        snoozeAction = lastSnoozedMessage?.snoozeAction
        snoozeEndDate = lastSnoozedMessage?.snoozeEndDate
    }

    private func getLastAction() -> ThreadLastAction? {
        guard let lastMessage = messages.last(where: { message in
            message.forwarded || message.answered
        }) else { return nil }

        if lastMessage.answered {
            return .reply
        }
        return .forward
    }

    func addMessageIfNeeded(newMessage: Message, using realm: Realm) {
        messageIds.insert(objectsIn: newMessage.linkedUids)

        guard let folder = realm.object(ofType: Folder.self, forPrimaryKey: folderId) else {
            return
        }
        let folderRole = folder.role

        // If the Message is deleted, but we are not in the Trash: ignore it, just leave.
        if folderRole != .trash && newMessage.inTrash {
            return
        }

        let shouldAddMessage: Bool
        switch folderRole {
        case .draft, .scheduledDrafts:
            shouldAddMessage = false
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

    public func lastMessageToExecuteAction(currentMailboxEmail: String) -> Message? {
        return messages.lastMessageToExecuteAction(currentMailboxEmail: currentMailboxEmail)
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
        case bimi
        case snoozeState
        case snoozeAction
        case snoozeEndDate
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
        forwarded: Bool,
        bimi: Bimi? = nil,
        snoozeState: SnoozeState? = nil,
        snoozeAction: String? = nil,
        snoozeEndDate: Date? = nil
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
        self.bimi = bimi
        self.snoozeState = snoozeState
        self.snoozeAction = snoozeAction
        self.snoozeEndDate = snoozeEndDate
    }

    public required init(from decoder: Decoder) throws {
        super.init()

        let container = try decoder.container(keyedBy: CodingKeys.self)
        uid = try container.decode(String.self, forKey: .uid)
        messages = try container.decode(List<Message>.self, forKey: .messages)
        unseenMessages = try container.decode(Int.self, forKey: .unseenMessages)
        from = try container.decode(List<Recipient>.self, forKey: .from)
        to = try container.decode(List<Recipient>.self, forKey: .to)
        subject = try container.decode(String?.self, forKey: .subject)
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        hasAttachments = try container.decode(Bool.self, forKey: .hasAttachments)
        hasDrafts = try container.decode(Bool.self, forKey: .hasDrafts)
        flagged = try container.decode(Bool.self, forKey: .flagged)
        answered = try container.decode(Bool.self, forKey: .answered)
        forwarded = try container.decode(Bool.self, forKey: .forwarded)
        bimi = try container.decodeIfPresent(Bimi.self, forKey: .bimi)
        snoozeState = try container.decodeIfPresent(SnoozeState.self, forKey: .snoozeState)
        snoozeAction = try container.decodeIfPresent(String.self, forKey: .snoozeAction)
        snoozeEndDate = try container.decodeIfPresent(Date.self, forKey: .snoozeEndDate)
    }

    override public init() {
        super.init()
    }
}

public extension Thread {
    /// Compute if the thread has external recipients
    func displayExternalRecipientState(mailboxManager: MailboxManager,
                                       recipientsList: List<Recipient>) -> DisplayExternalRecipientStatus.State {
        let externalDisplayStatus = DisplayExternalRecipientStatus(mailboxManager: mailboxManager, recipientsList: recipientsList)
        return externalDisplayStatus.state
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

public enum ThreadLastAction: String, PersistableEnum {
    case forward
    case reply
}
