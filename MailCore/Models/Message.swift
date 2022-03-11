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

public enum MessagePriority: String, Codable {
    case low, normal, high
}

public enum MessageDKIM: String, Codable {
    case valid
    case notValid = "not_valid"
    case notSigned = "not_signed"
}

public class Message: Object, Codable, Identifiable {
    @Persisted public var uid: String
    @Persisted public var msgId: String?
    @Persisted public var subject: String?
//    public var priority: MessagePriority
    @Persisted public var date: Date
    @Persisted public var size: Int
    @Persisted public var from: List<Recipient>
    @Persisted public var to: List<Recipient>
    @Persisted public var cc: List<Recipient>
    @Persisted public var bcc: List<Recipient>
    @Persisted public var replyTo: List<Recipient>
//    public var body: Body?
//    public var dkimStatus: MessageDKIM
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
