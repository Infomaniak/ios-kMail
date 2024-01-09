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
    case event, todo
}

public enum CalendarEventState: String, CaseIterable, Codable, PersistableEnum {
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

public final class CalendarEventAttendee: EmbeddedObject, Codable {
    @Persisted public var address: String
    @Persisted public var name: String
    @Persisted public var organizer: Bool
    @Persisted public var state: CalendarEventState?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        address = try container.decode(String.self, forKey: .address)
        name = try container.decode(String.self, forKey: .name)
        organizer = try container.decode(Bool.self, forKey: .organizer)
        state = try? container.decode(CalendarEventState?.self, forKey: .state)
    }
}

public final class CalendarEvent: EmbeddedObject, Codable {
    @Persisted public var type: CalendarEventType
    @Persisted public var title: String
    @Persisted public var location: String?
    @Persisted public var fullday: Bool
    @Persisted public var timezone: String?
    @Persisted public var start: Date
    @Persisted public var timezoneStart: String?
    @Persisted public var end: Date
    @Persisted public var timezoneEnd: String?
    @Persisted public var done: Bool
    @Persisted public var attendees: RealmSwift.List<CalendarEventAttendee>
}

public struct CalendarEventResponse: Codable {
    let userStoredEvent: CalendarEvent?
    let attachmentEvent: CalendarEvent
    let userStoredEventDeleted: Bool
}
