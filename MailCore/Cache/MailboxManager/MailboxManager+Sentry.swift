/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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
import Sentry

// MARK: - Sentry

public extension MailboxManager {
    enum Category: String {
        case APIError = "MailboxManagerAPIError"
        case RealmError = "MailboxManagerRealmError"
    }

    /// Observe API callback errors to generate a dashboard  on sentry
    @discardableResult
    func observeAPIErrors<T>(_ function: String = #function, _ task: @escaping () async throws -> T) async throws -> T {
        return try await observeErrors(category: .APIError, function: function, task: task)
    }

    /// Observe Local errors to generate a dashboard on sentry
    func observeRealmErrors<T>(_ function: String = #function, _ task: @escaping () async throws -> T) async throws -> T {
        try await observeErrors(category: .RealmError, function: function, task: task)
    }

    private func observeErrors<T>(category: Category, function: String, task: @escaping () async throws -> T) async throws -> T {
        do {
            return try await task()
        } catch {
            let categoryName = category.rawValue
            let metadata: [String: Any] = ["error": error, "localizedDescription": error.localizedDescription]

            // Add a breadcrumb
            let breadcrumb = Breadcrumb(level: .error, category: categoryName)
            breadcrumb.message = "\(function)~>|\(error)"
            breadcrumb.data = metadata
            SentrySDK.addBreadcrumb(breadcrumb)

            // Add error
            SentrySDK.capture(message: categoryName) { scope in
                scope.setExtras(metadata)
            }

            throw error
        }
    }
}
