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
import Sentry

public final class BackgroundRealm {
    private let configuration: Realm.Configuration
    private let queue: DispatchQueue

    public init(configuration: Realm.Configuration) {
        guard let fileURL = configuration.fileURL else {
            fatalError("Realm configurations without file URL not supported")
        }
        self.configuration = configuration
        queue = DispatchQueue(label: "com.infomaniak.mail.\(fileURL.lastPathComponent)", autoreleaseFrequency: .workItem)
    }

    private func getRealm() -> Realm {
        do {
            return try Realm(configuration: configuration, queue: queue)
        } catch {
            // We can't recover from this error but at least we report it correctly on Sentry
            Logging.reportRealmOpeningError(error, realmConfiguration: configuration)
        }
    }

    public func execute<T>(_ block: @escaping (Realm) -> T, completion: @escaping (T) -> Void) {
        BackgroundExecutor.executeWithBackgroundTask { [weak self] taskCompleted in
            self?.queue.async {
                guard let realm = self?.getRealm() else { return }
                realm.refresh()
                completion(block(realm))
                taskCompleted()
            }
        } onExpired: {
            let expiredBreadcrumb = Breadcrumb(level: .warning, category: "BackgroundRealm")
            expiredBreadcrumb.message = "Task expired before completing"
            SentrySDK.addBreadcrumb(expiredBreadcrumb)
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
