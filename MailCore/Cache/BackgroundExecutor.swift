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

import CocoaLumberjackSwift
import Foundation

enum BackgroundExecutor {
    typealias TaskCompletion = () -> Void
    static func executeWithBackgroundTask(_ block: @escaping (@escaping TaskCompletion) -> Void, onExpired: @escaping () -> Void) {
        let taskName = "executeWithBackgroundTask \(UUID().uuidString)"
        DDLogDebug("Starting task \(taskName)")
        let processInfos = ProcessInfo()
        let group = DispatchGroup()
        group.enter()
        processInfos.performExpiringActivity(withReason: taskName) { expired in
            if expired {
                onExpired()
                DDLogDebug("Expired task \(taskName)")
                group.leave()
            } else {
                block {
                    DDLogDebug("Ending task \(taskName)")
                    group.leave()
                }
                group.wait()
            }
        }
    }
}
