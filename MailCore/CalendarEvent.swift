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

public enum AttendeeState: String, CaseIterable, Codable, PersistableEnum {
    case yes = "ACCEPTED"
    case maybe = "TENTATIVE"
    case no = "DECLINED"

    public var icon: MailResourcesImages {
        switch self {
        case .yes:
            return MailResourcesAsset.checkmarkCircleFill
        case .maybe:
            return MailResourcesAsset.questionmarkCircleFill
        case .no:
            return MailResourcesAsset.crossCircleFill
        }
    }

    public var label: String {
        switch self {
        case .yes:
            return MailResourcesStrings.Localizable.buttonYes
        case .maybe:
            return MailResourcesStrings.Localizable.buttonMaybe
        case .no:
            return MailResourcesStrings.Localizable.buttonNo
        }
    }

    public var color: Color {
        switch self {
        case .yes:
            return MailResourcesAsset.greenColor.swiftUIColor
        case .maybe:
            return MailResourcesAsset.textSecondaryColor.swiftUIColor
        case .no:
            return MailResourcesAsset.redColor.swiftUIColor
        }
    }
}

public final class Attendee: EmbeddedObject, Codable {
    @Persisted public var email: String
    @Persisted public var name: String
    @Persisted public var isOrganizer: Bool
    @Persisted public var state: AttendeeState?

    override public init() {
        super.init()
    }

    public init(email: String, name: String, isOrganizer: Bool, state: AttendeeState? = nil) {
        self.email = email
        self.name = name
        self.isOrganizer = isOrganizer
        self.state = state
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        email = try container.decode(String.self, forKey: .email)
        name = try container.decode(String.self, forKey: .name)
        isOrganizer = try container.decode(Bool.self, forKey: .isOrganizer)
        state = try? container.decode(AttendeeState?.self, forKey: .state)
    }

    enum CodingKeys: String, CodingKey {
        case name
        case email = "address"
        case isOrganizer = "organizer"
        case state
    }
}

public enum CalendarEventType: String, Codable, PersistableEnum {
    case event
    case task = "todo"
}

public final class CalendarEvent: EmbeddedObject, Codable {
    @Persisted public var type: CalendarEventType
    @Persisted public var title: String
    @Persisted public var eventDescription: String
    @Persisted public var location: String?
    @Persisted public var fullDay: Bool
    @Persisted public var timezone: String?
    @Persisted public var start: Date
    @Persisted public var timezoneStart: String
    @Persisted public var end: Date
    @Persisted public var timezoneEnd: String
    @Persisted public var attendees: RealmSwift.List<Attendee>

    public var formattedDate: String {
        if Calendar.current.isDate(start, inSameDayAs: end) {
            return start.formatted(Constants.calendarDateFormat)
        } else {
            return "\(start.formatted(Constants.calendarSmallDateFormat)) - \(end.formatted(Constants.calendarSmallDateFormat))"
        }
    }

    public var formattedTime: String {
        if fullDay {
            return MailResourcesStrings.Localizable.calendarAllDayLong
        } else {
            return "\(start.formatted(Constants.calendarTimeFormat)) - \(end.formatted(Constants.calendarTimeFormat))"
        }
    }

    public var hasPassed: Bool {
        return end < Date.now
    }

    override public init() {
        super.init()
    }

    public init(
        type: CalendarEventType,
        title: String,
        eventDescription: String,
        location: String? = nil,
        fullDay: Bool,
        timezone: String? = nil,
        start: Date,
        timezoneStart: String,
        end: Date,
        timezoneEnd: String,
        attendees: RealmSwift.List<Attendee>
    ) {
        self.type = type
        self.title = title
        self.eventDescription = eventDescription
        self.location = location
        self.fullDay = fullDay
        self.timezone = timezone
        self.start = start
        self.timezoneStart = timezoneStart
        self.end = end
        self.timezoneEnd = timezoneEnd
        self.attendees = attendees
    }

    enum CodingKeys: String, CodingKey {
        case type
        case title
        case eventDescription = "description"
        case location
        case fullDay = "fullday"
        case timezone
        case start
        case timezoneStart
        case end
        case timezoneEnd
        case attendees
    }
}

public final class CalendarEventResponse: EmbeddedObject, Codable {
    @Persisted public var userStoredEvent: CalendarEvent?
    @Persisted public var attachmentEvent: CalendarEvent?
    @Persisted public var userStoredEventDeleted: Bool?

    public var event: CalendarEvent? {
        return userStoredEvent ?? attachmentEvent
    }
}
