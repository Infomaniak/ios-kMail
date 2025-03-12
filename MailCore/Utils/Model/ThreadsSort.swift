/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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

public protocol ThreadsSort: Sendable {
    var propertyName: String { get }
    var isAscending: Bool { get }

    func getReferenceDate(from thread: Thread) -> Date?
}

public struct DefaultThreadsSort: ThreadsSort {
    public let propertyName = "internalDate"
    public let isAscending = false

    public func getReferenceDate(from thread: Thread) -> Date? {
        return thread.internalDate
    }
}

public struct ScheduledThreadsSort: ThreadsSort {
    public let propertyName = "internalDate"
    public let isAscending = true

    public func getReferenceDate(from thread: Thread) -> Date? {
        return thread.internalDate
    }
}

public struct SnoozedThreadsSort: ThreadsSort {
    public let propertyName = "snoozeEndDate"
    public let isAscending = true

    public func getReferenceDate(from thread: Thread) -> Date? {
        return thread.snoozeEndDate
    }
}
