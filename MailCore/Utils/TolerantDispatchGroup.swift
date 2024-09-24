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

import CocoaLumberjackSwift
import Foundation

public class TolerantDispatchGroup {
    private let syncQueue = DispatchQueue(label: "com.infomaniak.TolerantDispatchGroup")
    private let dispatchGroup = DispatchGroup()
    private var callBalancer = 0

    public func enter() {
        syncQueue.sync {
            dispatchGroup.enter()
            callBalancer += 1
        }
    }

    public func leave() {
        syncQueue.sync {
            guard callBalancer > 0 else {
                Logger.general.error("TolerantDispatchGroup: Unbalanced call to leave()")
                return
            }

            dispatchGroup.leave()
            callBalancer -= 1
        }
    }

    public func wait() {
        dispatchGroup.wait()
    }
}
