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

public struct APIStatus {
    public let serverAvailable: Bool
    public let lastCheck: Date

    public init(isOnWorking: Bool, lastCheck: Date) {
        self.serverAvailable = isOnWorking
        self.lastCheck = lastCheck
    }

    public func isLastCheckClose(to date: Date, interval: TimeInterval = 10) -> Bool {
        return abs(lastCheck.timeIntervalSince(date)) <= interval
    }
}

@MainActor
public final class APIStatusManager: ObservableObject {
    public static let shared = APIStatusManager()

    @Published public var status: APIStatus

    private init() {
        status = APIStatus(isOnWorking: true, lastCheck: .now)
    }
}
