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
import InfomaniakCore
import InfomaniakCoreDB
import InfomaniakDI
import MailResources
import RealmSwift
import Sentry

// TODO: move to core
public extension String {
    /// Max length of a string before we need to truncate it.
    static let closeToMaxRealmSize = 14_000_000

    /// Truncate a string for compatibility with Realm if needed
    ///
    /// The string will be terminated by " [truncated]" if it was
    var truncatedForRealmIfNeeded: Self {
        Self.truncatedForRealmIfNeeded(self)
    }

    /// Truncate a string for compatibility with Realm if needed
    ///
    /// The string will be terminated by " [truncated]" if it was
    /// - Parameter input: an input string
    /// - Returns: The output string truncated if needed
    static func truncatedForRealmIfNeeded(_ input: String) -> String {
        if input.utf8.count > closeToMaxRealmSize {
            let index = input.index(input.startIndex, offsetBy: closeToMaxRealmSize)
            let truncatedValue = String(input[...index]) + " [truncated]"
            return truncatedValue
        } else {
            return input
        }
    }
}

public extension Collection<Message> {
    func sortedByDate() -> [Message] {
        sorted { $0.internalDate.compare($1.internalDate) == .orderedAscending }
    }
}

/// Class used to get a page of shortUids
public final class MessageUidsResult: Decodable {
    public let messageShortUids: [String]
    public let cursor: String

    private enum CodingKeys: String, CodingKey {
        case messageShortUids = "messagesUids"
        case cursor = "signature"
    }
}

public final class MessageByUidsResult: Decodable {
    public let messages: [Message]
}

public enum MessagePriority: String, Codable, PersistableEnum {
    case low, normal, high
}

public enum MessageDKIM: String, Codable, PersistableEnum {
    case valid
    case notValid = "not_valid"
    case notSigned = "not_signed"
}

public struct MessageActionResult: Codable {
    public var flagged: Int
}

public class MessageHeaders: EmbeddedObject, Codable {
    @Persisted public var xInfomaniakSpam: String

    private enum CodingKeys: String, CodingKey {
        case xInfomaniakSpam = "x-infomaniak-spam"
    }
}

public final class ReactionAuthor: EmbeddedObject {
    @Persisted public var recipient: Recipient?
    @Persisted public var bimi: Bimi?

    public convenience init(recipient: Recipient, bimi: Bimi?) {
        self.init()
        self.recipient = recipient
        self.bimi = bimi
    }
}

public final class MessageReaction: EmbeddedObject {
    @Persisted public var reaction: String
    @Persisted public var authors: List<ReactionAuthor>
    @Persisted public var hasUserReacted: Bool

    public convenience init(reaction: String, authors: [ReactionAuthor], hasUserReacted: Bool) {
        self.init()
        self.reaction = reaction
        self.authors = authors.toRealmList()
        self.hasUserReacted = hasUserReacted
    }
}

/// A Message has :
/// - Many threads
/// - One originalThread: parent thread
/// - One folder
public final class Message: Object, Decodable, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) public var uid = ""
    @Persisted public var messageId: String?
    @Persisted public var subject: String?
    @Persisted public var priority: MessagePriority
    @Persisted public var internalDate: Date
    @Persisted public var date: Date
    @Persisted public var size: Int
    @Persisted public var from: List<Recipient>
    @Persisted public var to: List<Recipient>
    @Persisted public var cc: List<Recipient>
    @Persisted public var bcc: List<Recipient>
    @Persisted public var replyTo: List<Recipient>
    @Persisted public var body: Body?
    @Persisted public var attachments: List<Attachment>
    @Persisted public var dkimStatus: MessageDKIM
    @Persisted public var attachmentsResources: String?
    @Persisted public var resource: String
    @Persisted public var downloadResource: String
    @Persisted public var draftResource: String?
    @Persisted public var swissTransferUuid: String?
    @Persisted public var folderId: String
    @Persisted public var references: String?
    @Persisted public var inReplyTo: String?
    @Persisted public var linkedUids: MutableSet<String>
    @Persisted public var preview: String
    @Persisted public var answered: Bool
    @Persisted public var isDraft: Bool
    @Persisted public var hasAttachments: Bool
    @Persisted public var seen: Bool
    @Persisted public var scheduled: Bool
    @Persisted public var isScheduledDraft: Bool?
    @Persisted public var scheduleDate: Date?
    @Persisted public var forwarded: Bool
    @Persisted public var flagged: Bool
    @Persisted public var hasUnsubscribeLink: Bool?
    @Persisted public var bimi: Bimi?
    @Persisted public var encrypted: Bool
    @Persisted public var encryptionPassword: String
    @Persisted public var cryptPasswordValidity: Date?
    @Persisted public var acknowledge: String?
    @Persisted private var headers: MessageHeaders?
    /// Threads where the message can be found
    @Persisted(originProperty: "messages") var threads: LinkingObjects<Thread>
    @Persisted(originProperty: "messages") private var folders: LinkingObjects<Folder>
    @Persisted(originProperty: "duplicates") var threadsDuplicatedIn: LinkingObjects<Thread>

    @Persisted public var isDisplayable = true

    @Persisted public var fullyDownloaded = false
    @Persisted public var fromSearch = false
    @Persisted public var inTrash = false
    @Persisted public var localSafeDisplay = false

    @Persisted public var calendarEventResponse: CalendarEventResponse?

    @Persisted public var swissTransferAttachment: SwissTransferAttachment?

    @Persisted public var snoozeState: SnoozeState?
    @Persisted public var snoozeUuid: String?
    @Persisted public var snoozeEndDate: Date?

    @Persisted public var emojiReaction: String?
    @Persisted public var emojiReactionNotAllowedReason: EmojiReactionNotAllowedReason?

    @Persisted public var reactions: List<MessageReaction>
    @Persisted public var reactionMessages: List<Message>

    public var shortUid: Int? {
        return Int(Constants.shortUid(from: uid))
    }

    public var recipients: [Recipient] {
        return Array(to) + Array(cc)
    }

    public var autoEncryptDisabledRecipients: [Recipient] {
        let result = to.toArray() + cc.toArray() + bcc.toArray()
        return result.filter { recipient in
            if !recipient.canAutoEncrypt {
                return true
            }
            return false
        }
    }

    public var isSpam: Bool {
        headers?.xInfomaniakSpam == "spam"
    }

    /// This is the parent thread situated in the parent folder.
    public var originalThread: Thread? {
        return threads.first { $0.folderId == folderId }
    }

    /// Parent folder of the message.
    /// (A message only has one folder)
    public var folder: Folder? {
        return folders.first
    }

    public var shouldComplete: Bool {
        return isDraft || !fullyDownloaded
    }

    public var isSnoozed: Bool {
        snoozeState == .snoozed && snoozeEndDate != nil && snoozeUuid != nil
    }

    public var isReaction: Bool {
        return emojiReaction?.isEmpty == false
    }

    public var hasReactions: Bool {
        return !reactions.isEmpty
    }

    public var formattedFrom: String {
        from.first?.htmlDescription ?? MailResourcesStrings.Localizable.unknownRecipientTitle
    }

    public var formattedSubject: String {
        return subject ?? MailResourcesStrings.Localizable.noSubjectTitle
    }

    public var displayDate: DisplayDate {
        if isScheduledDraft == true {
            return .scheduled(date)
        } else {
            return .normal(date)
        }
    }

    public var attachmentsSize: Int64 {
        return attachments.reduce(0) { $0 + $1.size }
    }

    public var duplicates: [Message] {
        guard let dup = originalThread?.duplicates.where({ $0.messageId == messageId }) else { return [] }
        return Array(dup)
    }

    public var notInlineAttachments: [Attachment] {
        if attachments.isManagedByRealm {
            return Array(attachments.filter("isInline == false"))
        } else {
            return attachments.filter { $0.isInline == false }
        }
    }

    public var isMovable: Bool {
        return !isDraft && !(isScheduledDraft ?? false)
    }

    public var canExecuteAction: Bool {
        @InjectService var featureAvailableProvider: FeatureAvailableProvider
        if featureAvailableProvider.isAvailable(.emojiReaction) {
            return !isDraft && isDisplayable
        }

        return !isDraft
    }

    public var hasUnseenReactions: Bool {
        return !reactionMessages.where { $0.seen == false }.isEmpty
    }

    public var hasPendingAcknowledgment: Bool {
        return acknowledge == "pending"
    }

    public func fromMe(currentMailboxEmail: String) -> Bool {
        return from.contains { $0.isMe(currentMailboxEmail: currentMailboxEmail) }
    }

    public func canReplyAll(currentMailboxEmail: String) -> Bool {
        let holder = recipientsForReplyTo(replyAll: true, currentMailboxEmail: currentMailboxEmail)
        return !holder.cc.isEmpty
    }

    public func recipientsForReplyTo(replyAll: Bool = false, currentMailboxEmail: String) -> RecipientHolder {
        let cleanedFrom = Array(from.detached()).filter { !$0.isMe(currentMailboxEmail: currentMailboxEmail) }
        let cleanedTo = Array(to.detached()).filter { !$0.isMe(currentMailboxEmail: currentMailboxEmail) }
        let cleanedReplyTo = Array(replyTo.detached()).filter { !$0.isMe(currentMailboxEmail: currentMailboxEmail) }
        let cleanedCc = Array(cc.detached()).filter { !$0.isMe(currentMailboxEmail: currentMailboxEmail) }

        var holder = RecipientHolder()

        let possibleRecipients: [(recipients: [Recipient], forCc: Bool)] = [
            (recipients: cleanedReplyTo, forCc: false),
            (recipients: cleanedFrom, forCc: false),
            (recipients: cleanedTo, forCc: true),
            (recipients: cleanedCc, forCc: true),
            (recipients: from.detached().toArray(), forCc: false)
        ]

        for value in possibleRecipients {
            if holder.to.isEmpty {
                holder.to = value.recipients
            } else if replyAll && value.forCc {
                holder.cc.append(contentsOf: value.recipients)
            }
        }

        return holder
    }

    public func computeReference() {
        if let references {
            linkedUids.insert(objectsIn: references.parseMessageIds())
        }
        if let inReplyTo {
            linkedUids.insert(objectsIn: inReplyTo.parseMessageIds())
        }
    }

    private enum CodingKeys: String, CodingKey {
        case uid
        case messageId = "msgId"
        case subject
        case priority
        case internalDate
        case date
        case size
        case from
        case to
        case cc
        case bcc
        case replyTo
        case body
        case attachments
        case dkimStatus
        case attachmentsResources
        case resource
        case downloadResource
        case draftResource
        case swissTransferUuid = "stUuid"
        case folderId
        case references
        case inReplyTo
        case preview
        case answered
        case isDraft
        case hasAttachments
        case seen
        case scheduled
        case isScheduledDraft
        case scheduleDate
        case forwarded
        case flagged
        case hasUnsubscribeLink
        case bimi
        case snoozeState
        case snoozeUuid
        case snoozeEndDate
        case encrypted
        case encryptionPassword
        case cryptPasswordValidity
        case emojiReaction
        case emojiReactionNotAllowedReason
        case headers
        case acknowledge
    }

    override init() {
        super.init()
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let uid = try values.decode(String.self, forKey: .uid)
        self.uid = uid
        if let msgId = try? values.decode(String.self, forKey: .messageId) {
            messageId = msgId
            linkedUids = [msgId].toRealmSet()
        }
        subject = try values.decodeIfPresent(String.self, forKey: .subject)
        priority = try values.decode(MessagePriority.self, forKey: .priority)
        internalDate = try values.decode(Date.self, forKey: .internalDate)
        if let date = (try? values.decode(Date.self, forKey: .date)) {
            self.date = date
        } else {
            date = try values.decode(Date.self, forKey: .internalDate)
        }
        size = try values.decode(Int.self, forKey: .size)
        from = try values.decode(List<Recipient>.self, forKey: .from)
        to = try values.decode(List<Recipient>.self, forKey: .to)
        cc = try values.decode(List<Recipient>.self, forKey: .cc)
        bcc = try values.decode(List<Recipient>.self, forKey: .bcc)
        replyTo = try values.decode(List<Recipient>.self, forKey: .replyTo)

        /// Preprocessing body with a ProxyBody
        let jsonBody = try values.decodeIfPresent(ProxyBody.self, forKey: .body)
        body = jsonBody?.realmObject()

        if let attachments = try? values.decode(List<Attachment>.self, forKey: .attachments) {
            self.attachments = attachments
        } else {
            attachments = List()
        }
        dkimStatus = try values.decode(MessageDKIM.self, forKey: .dkimStatus)
        attachmentsResources = try values.decodeIfPresent(String.self, forKey: .attachmentsResources)
        resource = try values.decode(String.self, forKey: .resource)
        downloadResource = try values.decode(String.self, forKey: .downloadResource)
        draftResource = try values.decodeIfPresent(String.self, forKey: .draftResource)
        swissTransferUuid = try values.decodeIfPresent(String.self, forKey: .swissTransferUuid)
        folderId = try values.decode(String.self, forKey: .folderId)
        references = try values.decodeIfPresent(String.self, forKey: .references)
        if let inReplyTo = try? values.decodeIfPresent(String.self, forKey: .inReplyTo) {
            self.inReplyTo = inReplyTo
        } else if let inReplyToList = try values.decodeIfPresent([String].self, forKey: .inReplyTo) {
            SentryDebug.messageHasInReplyTo(inReplyToList)
            inReplyTo = inReplyToList.first
        }

        preview = try values.decode(String.self, forKey: .preview)
        answered = try values.decode(Bool.self, forKey: .answered)
        isDraft = try values.decodeIfPresent(Bool.self, forKey: .isDraft) ?? false
        hasAttachments = try values.decode(Bool.self, forKey: .hasAttachments)
        seen = try values.decode(Bool.self, forKey: .seen)
        scheduled = try values.decode(Bool.self, forKey: .scheduled)
        isScheduledDraft = try values.decodeIfPresent(Bool.self, forKey: .isScheduledDraft)
        scheduleDate = try values.decodeIfPresent(Date.self, forKey: .scheduleDate)
        forwarded = try values.decode(Bool.self, forKey: .forwarded)
        flagged = try values.decode(Bool.self, forKey: .flagged)
        hasUnsubscribeLink = try values.decodeIfPresent(Bool.self, forKey: .hasUnsubscribeLink)
        bimi = try values.decodeIfPresent(Bimi.self, forKey: .bimi)

        snoozeState = try? values.decodeIfPresent(SnoozeState.self, forKey: .snoozeState)
        snoozeUuid = try? values.decodeIfPresent(String.self, forKey: .snoozeUuid)
        snoozeEndDate = try values.decodeIfPresent(Date.self, forKey: .snoozeEndDate)
        encrypted = try values.decodeIfPresent(Bool.self, forKey: .encrypted) ?? false
        encryptionPassword = try values.decodeIfPresent(String.self, forKey: .encryptionPassword) ?? ""
        cryptPasswordValidity = try values.decodeIfPresent(Date.self, forKey: .cryptPasswordValidity)

        emojiReaction = try values.decodeIfPresent(String.self, forKey: .emojiReaction)
        emojiReactionNotAllowedReason = try values.decodeIfPresent(
            EmojiReactionNotAllowedReason.self,
            forKey: .emojiReactionNotAllowedReason
        )

        headers = try? values.decodeIfPresent(MessageHeaders.self, forKey: .headers)
        acknowledge = try values.decodeIfPresent(String.self, forKey: .acknowledge)
    }

    public convenience init(
        uid: String,
        msgId: String,
        subject: String? = nil,
        priority: MessagePriority,
        internalDate: Date,
        date: Date,
        size: Int,
        from: [Recipient],
        to: [Recipient],
        cc: [Recipient],
        bcc: [Recipient],
        replyTo: [Recipient],
        body: Body? = nil,
        attachments: [Attachment],
        dkimStatus: MessageDKIM,
        resource: String,
        downloadResource: String,
        swissTransferUuid: String? = nil,
        folderId: String,
        references: String? = nil,
        preview: String,
        answered: Bool,
        isDraft: Bool,
        hasAttachments: Bool,
        seen: Bool,
        scheduled: Bool,
        isScheduledDraft: Bool? = nil,
        scheduleDate: Date? = nil,
        forwarded: Bool,
        flagged: Bool,
        hasUnsubscribeLink: Bool? = nil,
        bimi: Bimi? = nil,
        snoozeState: SnoozeState? = nil,
        snoozeUuid: String? = nil,
        snoozeEndDate: Date? = nil,
        emojiReaction: String? = nil,
        emojiReactionNotAllowedReason: EmojiReactionNotAllowedReason? = nil,
        acknowledge: String? = nil
    ) {
        self.init()

        self.uid = uid
        messageId = msgId
        self.subject = subject
        self.priority = priority
        self.internalDate = internalDate
        self.date = date
        self.size = size
        self.from = from.toRealmList()
        self.to = to.toRealmList()
        self.cc = cc.toRealmList()
        self.bcc = bcc.toRealmList()
        self.replyTo = replyTo.toRealmList()
        self.body = body
        self.attachments = attachments.toRealmList()
        self.dkimStatus = dkimStatus
        self.resource = resource
        self.downloadResource = downloadResource
        self.swissTransferUuid = swissTransferUuid
        self.folderId = folderId
        self.references = references
        self.preview = preview
        self.answered = answered
        self.isDraft = isDraft
        self.hasAttachments = hasAttachments
        self.seen = seen
        self.scheduled = scheduled
        self.isScheduledDraft = isScheduledDraft
        self.scheduleDate = scheduleDate
        self.forwarded = forwarded
        self.flagged = flagged
        self.hasUnsubscribeLink = hasUnsubscribeLink
        self.bimi = bimi
        fullyDownloaded = true
        self.snoozeState = snoozeState
        self.snoozeUuid = snoozeUuid
        self.snoozeEndDate = snoozeEndDate
        self.emojiReaction = emojiReaction
        self.emojiReactionNotAllowedReason = emojiReactionNotAllowedReason
        self.acknowledge = acknowledge
    }

    public func toThread() -> Thread {
        let thread = Thread(
            uid: "\(folderId)_\(uid)",
            messages: [self],
            unseenMessages: seen ? 0 : 1,
            from: Array(from),
            to: Array(to),
            subject: subject,
            internalDate: internalDate,
            date: date,
            hasAttachments: !attachments.isEmpty,
            hasDrafts: !(draftResource?.isEmpty ?? true),
            flagged: flagged,
            answered: answered,
            forwarded: forwarded,
            bimi: bimi,
            snoozeState: snoozeState,
            snoozeUuid: snoozeUuid,
            snoozeEndDate: snoozeEndDate,
            isLastMessageFromFolderSnoozed: isSnoozed
        )
        thread.messageIds = linkedUids
        thread.folderId = folderId
        return thread
    }
}
