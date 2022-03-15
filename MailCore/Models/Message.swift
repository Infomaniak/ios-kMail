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
import RealmSwift

public enum MessagePriority: String, Codable, PersistableEnum {
    case low, normal, high
}

public enum MessageDKIM: String, Codable, PersistableEnum {
    case valid
    case notValid = "not_valid"
    case notSigned = "not_signed"
}

public class Message: Object, Codable, Identifiable {
    @Persisted(primaryKey: true) public var uid: String
    @Persisted public var msgId: String?
    @Persisted public var subject: String?
    @Persisted public var priority: MessagePriority
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
    @Persisted public var attachmentsResource: String?
    @Persisted public var resource: String
    @Persisted public var downloadResource: String
    @Persisted public var draftResource: String?
    @Persisted public var stUuid: String?
    // public var duplicates: []
    @Persisted public var folderId: String
    @Persisted public var folder: String
    @Persisted public var references: String?
    @Persisted public var answered: Bool
    @Persisted public var isDuplicate: Bool?
    @Persisted public var isDraft: Bool
    @Persisted public var hasAttachments: Bool
    @Persisted public var seen: Bool
    @Persisted public var scheduled: Bool
    @Persisted public var forwarded: Bool
    @Persisted public var flagged: Bool
    @Persisted public var safeDisplay: Bool?
    @Persisted public var hasUnsubscribeLink: Bool?

    public var formattedSubject: String {
        return subject ?? "(no subject)"
    }

    public convenience init(
        uid: String,
        msgId: String,
        subject: String? = nil,
        priority: MessagePriority,
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
        stUuid: String? = nil,
        folderId: String,
        folder: String,
        references: String? = nil,
        answered: Bool,
        isDuplicate: Bool? = nil,
        isDraft: Bool,
        hasAttachments: Bool,
        seen: Bool,
        scheduled: Bool,
        forwarded: Bool,
        flagged: Bool,
        safeDisplay: Bool? = nil,
        hasUnsubscribeLink: Bool? = nil
    ) {
        self.init()

        self.uid = uid
        self.msgId = msgId
        self.subject = subject
        self.priority = priority
        self.date = date
        self.size = size

        self.from = List()
        self.from.append(objectsIn: from)

        self.to = List()
        self.to.append(objectsIn: to)

        self.cc = List()
        self.cc.append(objectsIn: cc)

        self.bcc = List()
        self.bcc.append(objectsIn: bcc)

        self.replyTo = List()
        self.replyTo.append(objectsIn: replyTo)

        self.body = body

        self.attachments = List()
        self.attachments.append(objectsIn: attachments)

        self.dkimStatus = dkimStatus
        self.resource = resource
        self.downloadResource = downloadResource
        self.stUuid = stUuid
        self.folderId = folderId
        self.folder = folder
        self.references = references
        self.answered = answered
        self.isDuplicate = isDuplicate
        self.isDraft = isDraft
        self.hasAttachments = hasAttachments
        self.seen = seen
        self.scheduled = scheduled
        self.forwarded = forwarded
        self.flagged = flagged
        self.safeDisplay = safeDisplay
        self.hasUnsubscribeLink = hasUnsubscribeLink
    }
}

public struct BodyResult: Codable {
    let body: Body
}

public class Body: EmbeddedObject, Codable {
    @Persisted public var value: String
    @Persisted public var type: String
    @Persisted public var subBody: String?
}

public struct SeenResult: Codable {
    public var flagged: Int
}
