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

public class DraftResponse: Object, Codable {
    public var uuid: String
    public var attachments: [Attachment]
    public var uid: String
}

public class Draft: Object, Codable, Identifiable {
    @Persisted(primaryKey: true) public var uuid: String
    @Persisted public var identityId: String?
    @Persisted public var inReplyToUid: String?
    @Persisted public var forwardedUid: String?
    @Persisted public var references: String?
    @Persisted public var inReplyTo: String?
    @Persisted public var mimeType: String
    @Persisted public var body: String
    @Persisted public var quote: String?
    @Persisted public var to: List<Recipient>
    @Persisted public var cc: List<Recipient>
    @Persisted public var bcc: List<Recipient>
    @Persisted public var subject: String?
    @Persisted public var ackRequest = false
    @Persisted public var priority: String?
    @Persisted public var stUuid: String?
    @Persisted public var attachments: List<Attachment>
//    @Persisted var action: SaveDraftOption?

    public var toValue: String {
        return recipientToValue(to)
    }

    public var ccValue: String {
        return recipientToValue(cc)
    }

    public var bccValue: String {
        return recipientToValue(bcc)
    }

    public var subjectValue: String {
        get {
            return subject ?? ""
        }
        set {
            subject = newValue
        }
    }

    private enum CodingKeys: String, CodingKey {
        case uuid
        case identityId
        case inReplyToUid
        case forwardedUid
        case references
        case inReplyTo
        case mimeType
        case body
        case quote
        case to
        case cc
        case bcc
        case subject
        case ackRequest
        case priority
        case stUuid
        case attachments
        case action
    }

    public required convenience init(from decoder: Decoder) throws {
        self.init()

        let values = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try values.decode(String.self, forKey: .uuid)
        identityId = try values.decodeIfPresent(String.self, forKey: .identityId)
        inReplyToUid = try values.decodeIfPresent(String.self, forKey: .inReplyToUid)
        forwardedUid = try values.decodeIfPresent(String.self, forKey: .forwardedUid)
        references = try values.decodeIfPresent(String.self, forKey: .references)
        inReplyTo = try values.decodeIfPresent(String.self, forKey: .inReplyTo)
        mimeType = try values.decode(String.self, forKey: .mimeType)
        body = try values.decode(String.self, forKey: .body)
        quote = try values.decodeIfPresent(String.self, forKey: .quote)
        to = try values.decode(List<Recipient>.self, forKey: .to)
        cc = try values.decode(List<Recipient>.self, forKey: .cc)
        bcc = try values.decode(List<Recipient>.self, forKey: .bcc)
        subject = try values.decodeIfPresent(String.self, forKey: .inReplyTo)
        ackRequest = try values.decode(Bool.self, forKey: .ackRequest)
        priority = try values.decodeIfPresent(String.self, forKey: .priority)
        stUuid = try values.decodeIfPresent(String.self, forKey: .stUuid)
        attachments = try values.decode(List<Attachment>.self, forKey: .to)
    }

    init(
        uuid: String = "",
        identityId: String? = nil,
        inReplyToUid: String? = nil,
        forwardedUid: String? = nil,
        references: String? = nil,
        inReplyTo: String? = nil,
        mimeType: String = "text/html",
        body: String = "",
        quote: String? = nil,
        to: [Recipient]? = nil,
        cc: [Recipient]? = nil,
        bcc: [Recipient]? = nil,
        subject: String = "",
        ackRequest: Bool = false,
        priority: String? = nil,
        stUuid: String? = nil,
        attachments: [Attachment]? = nil,
        action: SaveDraftOption? = nil
    ) {
        super.init()

        self.uuid = uuid
//        var signatureId: String?
//        if let signature = AccountManager.instance.signature {
//            signatureId = "\(signature.defaultSignatureId)"
//        }
        self.identityId = identityId // ?? signatureId
        self.inReplyToUid = inReplyToUid
        self.forwardedUid = forwardedUid
        self.references = references
        self.inReplyTo = inReplyTo
        self.mimeType = mimeType
        self.body = body
        self.quote = quote

        self.to = List()
        if let to = to {
            self.to.append(objectsIn: to)
        }

        self.cc = List()
        if let cc = cc {
            self.to.append(objectsIn: cc)
        }

        self.bcc = List()
        if let bcc = bcc {
            self.to.append(objectsIn: bcc)
        }

        self.subject = subject
        self.ackRequest = ackRequest
        self.priority = priority
        self.stUuid = stUuid

        self.attachments = List()
        if let attachments = attachments {
            self.attachments.append(objectsIn: attachments)
        }

//        self.action = action
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(uuid, forKey: .uuid)
        try container.encode(identityId, forKey: .identityId)
        try container.encode(inReplyToUid, forKey: .inReplyToUid)
        try container.encode(forwardedUid, forKey: .forwardedUid)
        try container.encode(references, forKey: .references)
        try container.encode(inReplyTo, forKey: .inReplyTo)
        try container.encode(mimeType, forKey: .mimeType)
        try container.encode(body, forKey: .body)
        try container.encode(quote, forKey: .quote)
        try container.encode(to, forKey: .to)
        try container.encode(cc, forKey: .cc)
        try container.encode(bcc, forKey: .bcc)
        try container.encode(subject, forKey: .subject)
        try container.encode(ackRequest, forKey: .ackRequest)
        try container.encode(priority, forKey: .priority)
        try container.encode(stUuid, forKey: .stUuid)
        let attachmentsArray = attachments.map { attachment in
            attachment.uuid
        }
//        try container.encode(attachmentsArray, forKey: .attachments)
//        try container.encode(action, forKey: .action)
    }

//    class func replying(to message: Message, mode: ReplyMode) -> Draft {
//        let subject: String
//        switch mode {
//        case .reply, .replyAll:
//            subject = "Re: \(message.formattedSubject)"
//        case .forward:
//            subject = "Fwd: \(message.formattedSubject)"
//        }
//        let header =
//            "<div><br></div><div><br></div><div class=\"ik_mail_quote\" ><div>Le \(message.date), \(message.from.first?.name ?? "") &lt;\(message.from.first?.email ?? "")&gt; a écrit :<br></div><blockquote class=\"ws-ng-quote\" style=\"margin:0px 0px 0px 0.8ex;border-left-width:1px;border-left-style:solid;border-left-color:rgb(204,204,204);padding-left:1ex\">"
//        let footer = "</blockquote></div>"
//        return Draft(inReplyToUid: mode.isReply ? message.uid : nil,
//                     forwardedUid: mode == .forward ? message.uid : nil,
//                     inReplyTo: message.msgId,
//                     body: "\(header)\(message.body?.value.replacingOccurrences(of: "'", with: "‘") ?? "")\(footer)",
//                     quote: "\(header)\(message.body?.value.replacingOccurrences(of: "'", with: "‘") ?? "")\(footer)",
//                     to: mode.isReply ? (message.replyTo.isEmpty ? message.from : message.replyTo) : nil,
//                     cc: mode == .replyAll ? (message.to + message.cc) : nil,
//                     bcc: mode == .replyAll ? message.bcc : nil,
//                     subject: subject,
//                     attachments: mode == .forward ? message.attachments : nil)
//    }

    private func valueToRecipient(_ value: String) -> [Recipient]? {
        guard !value.isEmpty else { return nil }
        return value.components(separatedBy: ",").map { Recipient(email: $0, name: "") }
    }

    private func recipientToValue(_ recipient: List<Recipient>?) -> String {
        return recipient?.map(\.email).joined(separator: ",") ?? ""
    }
}
