/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

public protocol CancelableResponse {
    var resource: String { get }
}

public struct SendResponse: Decodable {
    public let scheduledDate: Date
    public let cancelResource: String?

    enum CodingKeys: String, CodingKey {
        case scheduledDate = "etop"
        case cancelResource
    }
}

public struct CancelResponse: Decodable, CancelableResponse {
    public let cancelResource: String

    public var resource: String {
        return cancelResource
    }
}

public struct UndoResponse: Decodable, CancelableResponse {
    public let undoResource: String

    public var resource: String {
        return undoResource
    }
}

public struct ScheduleResponse: Decodable {
    public let uuid: String
    public let uid: String
    public let scheduleAction: String
}
