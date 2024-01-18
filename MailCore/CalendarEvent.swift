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
import MailResources
import RealmSwift
import SwiftUI

public enum CalendarEventType: String, Codable, PersistableEnum {
    case event
    case task = "todo"
}

public enum CalendarEventStatus: String, Codable, PersistableEnum {
    case confirmed = "CONFIRMED"
    case tentative = "TENTATIVE"
    case cancelled = "CANCELLED"
}

public enum CalendarEventWarning {
    case isCancelled, hasPassed

    public var label: String {
        switch self {
        case .isCancelled:
            return MailResourcesStrings.Localizable.warningEventIsCancelled
        case .hasPassed:
            return MailResourcesStrings.Localizable.warningEventHasPassed
        }
    }

    public var color: Color {
        switch self {
        case .isCancelled:
            return MailResourcesAsset.redColor.swiftUIColor
        case .hasPassed:
            return MailResourcesAsset.orangeColor.swiftUIColor
        }
    }
}

public final class CalendarEvent: EmbeddedObject, Codable {
    @Persisted public var type: CalendarEventType
    @Persisted public var title: String
    @Persisted public var eventDescription: String
    @Persisted public var location: String?
    @Persisted public var isFullDay: Bool
    @Persisted public var timezone: String?
    @Persisted public var start: Date
    @Persisted public var timezoneStart: String
    @Persisted public var end: Date
    @Persisted public var timezoneEnd: String
    @Persisted public var status: CalendarEventStatus?
    @Persisted public var attendees: RealmSwift.List<Attendee>

    public var warning: CalendarEventWarning? {
        if status == .cancelled {
            return .isCancelled
        } else if hasPassed {
            return .hasPassed
        } else {
            return nil
        }
    }

    public var organizer: Attendee? {
        return attendees.first(where: \.isOrganizer)
    }

    public var formattedDate: String {
        var computedEnd = end
        // When the event is `fullDay`, the start date is included and the end date excluded
        if isFullDay && !Calendar.current.isDate(start, inSameDayAs: end) {
            computedEnd = Calendar.current.date(byAdding: .day, value: -1, to: end) ?? end
        }

        if Calendar.current.isDate(start, inSameDayAs: computedEnd) {
            return start.formatted(Constants.calendarDateFormat)
        } else {
            return "\(start.formatted(Constants.calendarSmallDateFormat)) - \(computedEnd.formatted(Constants.calendarSmallDateFormat))"
        }
    }

    public var formattedTime: String {
        if isFullDay {
            return MailResourcesStrings.Localizable.calendarAllDayLong
        } else {
            return "\(start.formatted(Constants.calendarTimeFormat)) - \(end.formatted(Constants.calendarTimeFormat))"
        }
    }

    private var hasPassed: Bool {
        return end < .now
    }

    override public init() {
        super.init()
    }

    public init(
        type: CalendarEventType,
        title: String,
        eventDescription: String,
        location: String? = nil,
        isFullDay: Bool,
        timezone: String? = nil,
        start: Date,
        timezoneStart: String,
        end: Date,
        timezoneEnd: String,
        status: CalendarEventStatus?,
        attendees: RealmSwift.List<Attendee>
    ) {
        self.type = type
        self.title = title
        self.eventDescription = eventDescription
        self.location = location
        self.isFullDay = isFullDay
        self.timezone = timezone
        self.start = start
        self.timezoneStart = timezoneStart
        self.end = end
        self.timezoneEnd = timezoneEnd
        self.status = status
        self.attendees = attendees
    }

    // We need to create our own init
    // The date from the API is not always in ISO 8601 format, but changes
    // when the event lasts the entire day
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(CalendarEventType.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        eventDescription = try container.decode(String.self, forKey: .eventDescription)
        location = try container.decode(String?.self, forKey: .location)
        isFullDay = try container.decode(Bool.self, forKey: .isFullDay)
        timezone = try container.decode(String?.self, forKey: .timezone)
        timezoneStart = try container.decode(String.self, forKey: .timezoneStart)
        timezoneEnd = try container.decode(String.self, forKey: .timezoneEnd)
        status = try container.decode(CalendarEventStatus?.self, forKey: .status)
        attendees = try container.decode(List<Attendee>.self, forKey: .attendees)

        let startString = try container.decode(String.self, forKey: .start)
        start = Constants.decodeDateCorrectly(startString) ?? .now
        let endString = try container.decode(String.self, forKey: .end)
        end = Constants.decodeDateCorrectly(endString) ?? .now
    }

    enum CodingKeys: String, CodingKey {
        case type
        case title
        case eventDescription = "description"
        case location
        case isFullDay = "fullday"
        case timezone
        case start
        case timezoneStart
        case end
        case timezoneEnd
        case status
        case attendees
    }

    public func iAmPartOfAttendees(currentMailboxEmail: String) -> Bool {
        return attendees.contains { $0.isMe(currentMailboxEmail: currentMailboxEmail) }
    }
}

public enum AttachmentEventMethod: String, Codable, PersistableEnum {
    case request = "REQUEST"
    case reply = "REPLY"
}

public final class CalendarEventResponse: EmbeddedObject, Codable {
    @Persisted public var userStoredEvent: CalendarEvent?
    @Persisted public var attachmentEvent: CalendarEvent?
    @Persisted public var userStoredEventDeleted: Bool?
    @Persisted public var attachmentEventMethod: AttachmentEventMethod

    public var event: CalendarEvent? {
        return userStoredEvent ?? attachmentEvent
    }
}
