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
import InfomaniakDI
import MailResources
import OrderedCollections
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
    @Persisted private var messagesToDisplay: List<Message>
    @Persisted public var unseenMessages: Int
    @Persisted public var from: List<Recipient>
    @Persisted public var to: List<Recipient>
    @Persisted public var subject: String?
    @Persisted(indexed: true) public var internalDate: Date
    @Persisted public var date: Date
    @Persisted public var hasAttachments: Bool
    @Persisted public var hasDrafts: Bool
    @Persisted public var flagged: Bool
    @Persisted public var answered: Bool
    @Persisted public var forwarded: Bool
    @Persisted public var folderId = ""
    @Persisted(originProperty: "threads") private var folders: LinkingObjects<Folder>
    @Persisted public var fromSearch = false
    @Persisted public var searchFolderName: String?
    @Persisted public var bimi: Bimi?

    @Persisted public var isDraft = false

    @Persisted public var duplicates = List<Message>()
    @Persisted public var messageIds: MutableSet<String>

    @Persisted public var snoozeState: SnoozeState?
    @Persisted public var snoozeUuid: String?
    @Persisted public var snoozeEndDate: Date?
    @Persisted public var isLastMessageFromFolderSnoozed = false

    /// This property is used to remove threads from list before network call is finished
    @Persisted public var isMovedOutLocally = false

    @Persisted public var numberOfScheduledDraft = 0

    public var id: String {
        return uid
    }

    public var displayMessages: List<Message> {
        @InjectService var featureAvailableProvider: FeatureAvailableProvider
        if featureAvailableProvider.isAvailable(.emojiReaction) {
            return messagesToDisplay
        } else {
            return messages
        }
    }

    public var lastAction: ThreadLastAction? {
        if answered {
            return .reply
        } else if forwarded {
            return .forward
        } else {
            return nil
        }
    }

    public var displayDate: DisplayDate {
        if containsOnlyScheduledDrafts {
            return .scheduled(date)
        } else if snoozeState != nil, let snoozeEndDate {
            return .snoozed(snoozeEndDate)
        } else {
            return .normal(date)
        }
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

    public var containsOnlyScheduledDrafts: Bool {
        return numberOfScheduledDraft == messages.count
    }

    private var messagesAndDuplicates: [Message] {
        return messages.toArray() + duplicates.toArray()
    }

    public var isSnoozed: Bool {
        snoozeState == .snoozed && snoozeEndDate != nil && snoozeUuid != nil
    }

    public var isMovable: Bool {
        messages.allSatisfy(\.isMovable)
    }

    public func updateUnseenMessages() {
        unseenMessages = messagesAndDuplicates.filter { !$0.seen }.count
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

        if isSnoozed {
            let snoozedFolder = realm.objects(Folder.self).where { $0.role == .snoozed }
            searchFolderName = snoozedFolder.first?.localizedName
        } else {
            let parentFolder = realm.object(ofType: Folder.self, forPrimaryKey: message.folderId)
            searchFolderName = parentFolder?.localizedName
        }
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
        case internalDate
        case date
        case hasAttachments
        case hasDrafts
        case flagged
        case answered
        case forwarded
        case bimi
        case snoozeState
        case snoozeUuid
        case snoozeEndDate
    }

    public convenience init(
        uid: String,
        messages: [Message],
        unseenMessages: Int,
        from: [Recipient],
        to: [Recipient],
        subject: String? = nil,
        internalDate: Date,
        date: Date,
        hasAttachments: Bool,
        hasDrafts: Bool,
        flagged: Bool,
        answered: Bool,
        forwarded: Bool,
        bimi: Bimi? = nil,
        snoozeState: SnoozeState? = nil,
        snoozeUuid: String? = nil,
        snoozeEndDate: Date? = nil,
        isLastMessageFromFolderSnoozed: Bool = false
    ) {
        self.init()

        self.uid = uid
        self.messages = messages.toRealmList()
        self.unseenMessages = unseenMessages
        self.from = from.toRealmList()
        self.to = to.toRealmList()
        self.subject = subject
        self.internalDate = internalDate
        self.date = date
        self.hasAttachments = hasAttachments
        self.hasDrafts = hasDrafts
        self.flagged = flagged
        self.answered = answered
        self.forwarded = forwarded
        self.bimi = bimi
        self.snoozeState = snoozeState
        self.snoozeUuid = snoozeUuid
        self.snoozeEndDate = snoozeEndDate
        self.isLastMessageFromFolderSnoozed = isLastMessageFromFolderSnoozed

        numberOfScheduledDraft = messages.count { $0.isScheduledDraft == true }
    }

    public required init(from decoder: Decoder) throws {
        super.init()

        let container = try decoder.container(keyedBy: CodingKeys.self)
        uid = try container.decode(String.self, forKey: .uid)
        messages = try container.decode(List<Message>.self, forKey: .messages)
        messagesToDisplay = messages.filter { !$0.isReaction }.toRealmList()
        unseenMessages = try container.decode(Int.self, forKey: .unseenMessages)
        from = try container.decode(List<Recipient>.self, forKey: .from)
        to = try container.decode(List<Recipient>.self, forKey: .to)
        subject = try container.decode(String?.self, forKey: .subject)
        internalDate = try container.decode(Date.self, forKey: .internalDate)
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        hasAttachments = try container.decode(Bool.self, forKey: .hasAttachments)
        hasDrafts = try container.decode(Bool.self, forKey: .hasDrafts)
        flagged = try container.decode(Bool.self, forKey: .flagged)
        answered = try container.decode(Bool.self, forKey: .answered)
        forwarded = try container.decode(Bool.self, forKey: .forwarded)
        bimi = try container.decodeIfPresent(Bimi.self, forKey: .bimi)
        snoozeState = try container.decodeIfPresent(SnoozeState.self, forKey: .snoozeState)
        snoozeUuid = try container.decodeIfPresent(String.self, forKey: .snoozeUuid)
        snoozeEndDate = try container.decodeIfPresent(Date.self, forKey: .snoozeEndDate)

        numberOfScheduledDraft = messages.count { $0.isScheduledDraft == true }
    }

    override public init() {
        super.init()
    }
}

public extension Thread {
    typealias MessageId = String

    /// Re-generate `Thread` properties given the messages it contains.
    func recomputeOrFail(currentAccountEmail: String) throws {
        messages = messages.sortedByDate().toRealmList()
        messagesToDisplay = List()

        guard let lastMessageFromFolder else {
            throw MailError.threadHasNoMessageInFolder
        }

        resetThread()

        subject = messages.first?.subject
        internalDate = lastMessageFromFolder.internalDate
        date = lastMessageFromFolder.date
        isLastMessageFromFolderSnoozed = lastMessageFromFolder.isSnoozed

        let messagesById = getMessageById(messages: messages)

        for message in messages {
            messageIds.insert(objectsIn: message.linkedUids)
            from.append(objectsIn: message.from.detached())
            to.append(objectsIn: message.to.detached())

            message.reactions = List()
            message.reactionMessages = List()

            if !message.seen {
                unseenMessages += 1
            }
            if message.flagged {
                flagged = true
            }
            if message.hasAttachments {
                hasAttachments = true
            }
            if message.isDraft {
                hasDrafts = true
            }
            if message.answered {
                answered = true
                forwarded = false
            }
            if message.forwarded {
                answered = false
                forwarded = true
            }
            if message.isScheduledDraft == true {
                numberOfScheduledDraft += 1
            }
            if UserDefaults.shared.threadMode == .conversation && message.isReaction {
                let hasAppliedReaction = applyReactionIfPossible(
                    from: message,
                    messagesById: messagesById,
                    currentAccountEmail: currentAccountEmail
                )

                message.isDisplayable = !(hasAppliedReaction || message.isDraft)
            } else {
                messagesToDisplay.append(message)
            }

            updateSnooze(from: message)
        }

        for duplicate in duplicates {
            if !duplicate.seen {
                unseenMessages += 1
            }
            updateSnooze(from: duplicate)
        }
    }

    private func resetThread() {
        messageIds = MutableSet()
        from = List()
        to = List()

        unseenMessages = 0
        numberOfScheduledDraft = 0

        flagged = false
        hasAttachments = false
        hasDrafts = false
        answered = false
        forwarded = false
        isLastMessageFromFolderSnoozed = false

        snoozeState = nil
        snoozeUuid = nil
        snoozeEndDate = nil
    }

    private func applyReactionIfPossible(from message: Message, messagesById: [MessageId: Message],
                                         currentAccountEmail: String) -> Bool {
        guard let emojiReaction = message.emojiReaction,
              let targetMessageIds = message.inReplyTo?.parseMessageIds()
        else { return false }

        var hasBeenApplied = false
        for targetMessageId in targetMessageIds {
            guard let targetMessage = messagesById[targetMessageId] else {
                continue
            }

            var hasUserReacted = false
            var authors = [ReactionAuthor]()
            for recipient in message.from {
                authors.append(ReactionAuthor(recipient: recipient.detached(), bimi: message.bimi?.detached()))
                if recipient.isCurrentUser(currentAccountEmail: currentAccountEmail) {
                    hasUserReacted = true
                }
            }

            if let emojiReaction = targetMessage.reactions.where({ $0.reaction == emojiReaction }).first {
                emojiReaction.authors.append(objectsIn: authors)
                if hasUserReacted {
                    emojiReaction.hasUserReacted = true
                }
            } else {
                let messageReaction = MessageReaction(reaction: emojiReaction, authors: authors, hasUserReacted: hasUserReacted)
                targetMessage.reactions.append(messageReaction)
            }
            targetMessage.reactionMessages.append(message)

            hasBeenApplied = true
        }

        return hasBeenApplied
    }

    private func updateSnooze(from message: Message) {
        guard let messageSnoozeState = message.snoozeState else { return }

        snoozeState = messageSnoozeState
        snoozeUuid = message.snoozeUuid
        snoozeEndDate = message.snoozeEndDate
    }

    private func getMessageById(messages: List<Message>) -> [MessageId: Message] {
        var messageById = [MessageId: Message]()
        for message in messages {
            guard let messageId = message.messageId else { continue }
            messageById[messageId] = message
        }

        return messageById
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

public enum ThreadLastAction: Sendable {
    case forward
    case reply
}
