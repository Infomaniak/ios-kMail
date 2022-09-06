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
import RealmSwift

public class BackgroundRealm {
    private var realm: Realm!
    private let queue: DispatchQueue

    init(configuration: Realm.Configuration) {
        guard let fileURL = configuration.fileURL else {
            fatalError("Realm configurations without file URL not supported")
        }
        queue = DispatchQueue(label: "com.infomaniak.mail.\(fileURL.lastPathComponent)", autoreleaseFrequency: .workItem)

        queue.sync {
            do {
                realm = try Realm(configuration: configuration, queue: queue)
            } catch {
                // We can't recover from this error but at least we report it correctly on Sentry
                Logging.reportRealmOpeningError(error, realmConfiguration: configuration)
            }
        }
    }

    public func execute<T>(_ block: (Realm) -> T) -> T {
        return queue.sync { block(realm) }
    }

    public func execute<T>(_ block: (Realm) -> T) async -> T {
        return await withCheckedContinuation { (continuation: CheckedContinuation<T, Never>) in
            let result = execute(block)
            continuation.resume(returning: result)
        }
    }
}
