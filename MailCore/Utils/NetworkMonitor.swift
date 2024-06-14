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
import Network

public class NetworkMonitor: ObservableObject {
    @Published public var isConnected = true
    @Published public var isCellular = false

    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue.global()

    public static let shared = NetworkMonitor()

    private init() {}

    public func start() {
        if monitor == nil {
            monitor = NWPathMonitor()
            monitor?.start(queue: queue)
        }
        monitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.isCellular = path.usesInterfaceType(.cellular)
            }
        }
    }

    public func stop() {
        monitor?.cancel()
        monitor = nil
    }
}
