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
import Sentry

extension AccountManager {
    enum Category {
        static let accountManagerDomain = "AccountManagerDomainError"
        static let accountManagerAPI = "AccountManagerAPIError"
    }

    /// Track a local `ErrorDomain` error in order to generate a dashboard on Sentry related to the AccountManager.
    func logError(_ error: ErrorDomain, _ function: String = #function) {
        logErrorToSentry(category: Category.accountManagerDomain, error: error, function: function)
    }

    /// Observe API callback errors to generate a dashboard  on sentry related to the AccountManager.
    @discardableResult
    func observeAPIErrors<T>(function: String = #function, task: @escaping () async throws -> T) async throws -> T {
        do {
            return try await task()
        } catch {
            logErrorToSentry(category: Category.accountManagerAPI, error: error, function: function)

            throw error
        }
    }

    /// Process an error to Sentry
    private func logErrorToSentry(category: String, error: Error, function: String) {
        let metadata: [String: Any] = ["error": error, "localizedDescription": error.localizedDescription]

        // Add a breadcrumb for any error
        let breadcrumb = Breadcrumb(level: .error, category: category)
        breadcrumb.message = "\(function)~>|\(error)"
        breadcrumb.data = metadata
        SentrySDK.addBreadcrumb(breadcrumb)

        // Add error
        SentrySDK.capture(message: category) { scope in
            scope.setExtras(metadata)
        }
    }
}
