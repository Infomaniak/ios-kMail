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
import InfomaniakCore
import RealmSwift
import Sentry

/// Conforming to `RealmAccessible` to get a standard `.getRealm` function
extension BackgroundRealm: MailCoreRealmAccessible {}

/// Async await db transactions. Can provide a Realm.
public final class BackgroundRealm {
    private let queue: DispatchQueue

    public let realmConfiguration: Realm.Configuration

    public init(configuration: Realm.Configuration) {
        guard let fileURL = configuration.fileURL else {
            fatalError("Realm configurations without file URL not supported")
        }
        realmConfiguration = configuration
        queue = DispatchQueue(label: "com.infomaniak.mail.\(fileURL.lastPathComponent)", autoreleaseFrequency: .workItem)
    }

    public func execute<T>(_ block: @escaping (Realm) -> T, completion: @escaping (T) -> Void) {
        let expiringActivity = ExpiringActivity()
        expiringActivity.start()
        queue.async {
            let realm = self.getRealm()
            completion(block(realm))
            expiringActivity.endAll()
        }
    }

    public func execute<T>(_ block: @escaping (Realm) -> T) async -> T {
        return await withCheckedContinuation { (continuation: CheckedContinuation<T, Never>) in
            execute(block) { result in
                continuation.resume(returning: result)
            }
        }
    }
}
