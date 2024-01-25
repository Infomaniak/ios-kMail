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

public final class Attendee: EmbeddedObject, Correspondent, Codable {
    @Persisted public var email: String
    @Persisted public var name: String
    @Persisted public var isOrganizer: Bool
    @Persisted public var state: AttendeeState?

    override public init() {
        super.init()
    }

    public convenience init(email: String, name: String, isOrganizer: Bool, state: AttendeeState? = nil) {
        self.init()
        self.email = email
        self.name = name
        self.isOrganizer = isOrganizer
        self.state = state
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        email = try container.decode(String.self, forKey: .email)
        name = try container.decode(String?.self, forKey: .name) ?? ""
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
