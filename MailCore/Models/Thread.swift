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

public struct ThreadResult: Codable {
    let threads: [Thread]?
}

public struct Thread: Codable, Identifiable {
    public var uid: String
    public var messagesCount: Int
    public var uniqueMessagesCount: Int
    public var deletedMessagesCount: Int
    public var messages: [Message]
    public var unseenMessages: Int
//    public var from: [Recipient]
//    public var to: [Recipient]
//    public var cc: [Recipient]
//    public var bcc: [Recipient]
    public var subject: String?
    public var date: Date
    public var hasAttachments: Bool
    public var hasStAttachments: Bool
    public var hasDrafts: Bool
    public var flagged: Bool
    public var answered: Bool
    public var forwarded: Bool
    public var size: Int

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
