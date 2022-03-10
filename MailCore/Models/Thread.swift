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

public struct ThreadResult: Codable {
    let threads: [Thread]?
}

public class Thread: Object, Codable, Identifiable {
    @Persisted(primaryKey: true) public var uid: String
    @Persisted public var messagesCount: Int
    @Persisted public var uniqueMessagesCount: Int
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

    public var id: String {
        return uid
    }

    public var formattedSubject: String {
        return subject ?? "(no subject)"
    }
}

public enum Filter: String, CaseIterable, Identifiable {
    case all, seen, unseen, starred, unstarred

    var title: String {
        switch self {
        case .all:
            return "All"
        case .seen:
            return "Seen"
        case .unseen:
            return "Unseen"
        case .starred:
            return "Starred"
        case .unstarred:
            return "Unstarred"
        }
    }

    public var id: String {
        return rawValue
    }
}
