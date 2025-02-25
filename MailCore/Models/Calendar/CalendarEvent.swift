/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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
    @Persisted public var id: Int
    @Persisted public var type: CalendarEventType
    @Persisted public var title: String
    @Persisted public var location: String?
    @Persisted public var isFullDay: Bool
    @Persisted public var start: Date
    @Persisted public var end: Date
    @Persisted public var status: CalendarEventStatus?
    @Persisted public var attendees: RealmSwift.List<Attendee>
    @Persisted public var bookableResource: BookableResource?

    @Persisted(originProperty: "userStoredEvent") public var userStoredParent: LinkingObjects<CalendarEventResponse>
    @Persisted(originProperty: "attachmentEvent") public var attachmentParent: LinkingObjects<CalendarEventResponse>
    public var parent: CalendarEventResponse? {
        userStoredParent.first ?? attachmentParent.first
    }

    public var isAnInvitation: Bool {
        return parent?.attachmentEventMethod == .request || parent?.attachmentEventMethod == nil
    }

    public var isCancelled: Bool {
        return status == .cancelled
    }

    public var hasPassed: Bool {
        return end < .now
    }

    public var warning: CalendarEventWarning? {
        if isCancelled {
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

    public var formattedDateTime: String {
        if isFullDay {
            return formatFullDayDate()
        } else {
            return formatStandardDate()
        }
    }

    override public init() {
        super.init()
    }

    public init(
        id: Int,
        type: CalendarEventType,
        title: String,
        location: String? = nil,
        isFullDay: Bool,
        start: Date,
        end: Date,
        status: CalendarEventStatus?,
        attendees: RealmSwift.List<Attendee>,
        bookableResource: BookableResource? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.location = location
        self.isFullDay = isFullDay
        self.start = start
        self.end = end
        self.status = status
        self.attendees = attendees
        self.bookableResource = bookableResource
    }

    // We need to create our own init
    // The date from the API is not always in ISO 8601 format, but changes
    // when the event lasts the entire day
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        type = try container.decode(CalendarEventType.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        location = try container.decode(String?.self, forKey: .location)
        isFullDay = try container.decode(Bool.self, forKey: .isFullDay)
        status = try? container.decode(CalendarEventStatus?.self, forKey: .status)
        attendees = try container.decode(List<Attendee>.self, forKey: .attendees)
        bookableResource = try container.decodeIfPresent(BookableResource.self, forKey: .bookableResource)

        let startString = try container.decode(String.self, forKey: .start)
        start = Constants.decodeDateCorrectly(startString) ?? .now
        let endString = try container.decode(String.self, forKey: .end)
        end = Constants.decodeDateCorrectly(endString) ?? .now
    }

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case location
        case isFullDay = "fullday"
        case start
        case end
        case status
        case attendees
        case bookableResource
    }

    public func getMyFrozenAttendee(currentMailboxEmail: String) -> Attendee? {
        return attendees.first { $0.isMe(currentMailboxEmail: currentMailboxEmail) }?.freezeIfNeeded()
    }

    private func formatStandardDate() -> String {
        if Calendar.current.isDate(start, inSameDayAs: end) {
            return "\(start.formatted(.calendarDateFull))\n\(start.formatted(.calendarTime)) - \(end.formatted(.calendarTime))"
        } else {
            return "\(start.formatted(.calendarDateTime)) -\n\(end.formatted(.calendarDateTime))"
        }
    }

    private func formatFullDayDate() -> String {
        var computedEnd = end
        if !Calendar.current.isDate(start, inSameDayAs: end) {
            computedEnd = Calendar.current.date(byAdding: .day, value: -1, to: end) ?? end
        }

        var date = ""
        if Calendar.current.isDate(start, inSameDayAs: computedEnd) {
            date = start.formatted(.calendarDateFull)
        } else {
            date = "\(start.formatted(.calendarDateShort)) - \(computedEnd.formatted(.calendarDateShort))"
        }

        return "\(date)\n\(MailResourcesStrings.Localizable.calendarAllDayLong)"
    }
}
