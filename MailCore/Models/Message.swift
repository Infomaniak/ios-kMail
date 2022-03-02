//
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

public enum MessagePriority: String, Codable {
    case low, normal, high
}

public enum MessageDKIM: String, Codable {
    case valid
    case notValid = "not_valid"
    case notSigned = "not_signed"
}

public class Message: Codable, Identifiable, ObservableObject {
    public var uid: String
    public var msgId: String?
    public var subject: String?
//    public var priority: MessagePriority
    public var date: Date
    public var size: Int
//    public var from: [Recipient]
//    public var to: [Recipient]
//    public var cc: [Recipient]
//    public var bcc: [Recipient]
//    public var replyTo: [Recipient]
//    public var body: Body?
//    public var dkimStatus: MessageDKIM
    public var attachmentsResource: String?
    public var resource: String
    public var downloadResource: String
    public var draftResource: String?
    public var stUuid: String?
    // public var duplicates: []
    public var folderId: String
    public var folder: String
    public var references: String?
    public var answered: Bool
    public var isDuplicate: Bool?
    public var isDraft: Bool
    public var hasAttachments: Bool
    public var seen: Bool
    public var scheduled: Bool
    public var forwarded: Bool
    public var flagged: Bool
    public var safeDisplay: Bool?
    public var hasUnsubscribeLink: Bool?

    public var formattedSubject: String {
        return subject ?? "(no subject)"
    }

//    public var recipients: [Recipient] {
//        return to + cc + bcc
//    }
}

public struct BodyResult: Codable {
    let body: Body
}

public class Body: Codable {
    public var value: String
    public var type: String
    public var subBody: String?
}

public struct SeenResult: Codable {
    public var flagged: Int
}
