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

import RealmSwift

public struct CalendarReplyRequest: Codable {
    public var reply: AttendeeState
}

public final class CalendarEventResponse: EmbeddedObject, Codable {
    @Persisted public var userStoredEvent: CalendarEvent?
    @Persisted public var attachmentEvent: CalendarEvent?
    @Persisted public var userStoredEventDeleted: Bool?
    @Persisted public var attachmentEventMethod: AttachmentEventMethod?

    @Persisted(originProperty: "calendarEvent") public var messages: LinkingObjects<Message>
    public var message: Message? {
        messages.first
    }

    public var event: CalendarEvent? {
        return userStoredEvent ?? attachmentEvent
    }

    override public init() {
        super.init()
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userStoredEvent = try container.decode(CalendarEvent?.self, forKey: .userStoredEvent)
        attachmentEvent = try container.decode(CalendarEvent?.self, forKey: .attachmentEvent)
        userStoredEventDeleted = try container.decode(Bool?.self, forKey: .userStoredEventDeleted)
        attachmentEventMethod = try? container.decode(AttachmentEventMethod?.self, forKey: .attachmentEventMethod)
    }

    enum CodingKeys: CodingKey {
        case userStoredEvent
        case attachmentEvent
        case userStoredEventDeleted
        case attachmentEventMethod
    }
}
