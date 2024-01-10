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
import InfomaniakCoreUI
import InfomaniakDI
import Sentry

public func tryOrDisplayError(_ body: () throws -> Void) {
    do {
        try body()
    } catch {
        displayErrorIfNeeded(error: error)
    }
}

public func tryOrDisplayError(_ body: () async throws -> Void) async {
    do {
        try await body()
    } catch {
        displayErrorIfNeeded(error: error)
    }
}

private func displayErrorIfNeeded(error: Error) {
    @InjectService var snackbarPresenter: SnackBarPresentable
    if let error = error as? MailError {
        if error.shouldDisplay {
            if let errorDescription = error.errorDescription {
                snackbarPresenter.show(message: errorDescription)
            }
        } else {
            SentrySDK.capture(message: "Encountered error that we didn't display to the user") { scope in
                scope.setContext(
                    value: ["Code": error.code, "Raw": error],
                    key: "Error"
                )
            }
        }
        DDLogError("MailError: \(error)")
    } else if error.shouldDisplay {
        snackbarPresenter.show(message: error.localizedDescription)
        DDLogError("Error: \(error)")
    }
}

public extension Error {
    var shouldDisplay: Bool {
        guard !Bundle.main.isExtension else {
            return false
        }

        switch asAFError {
        case .explicitlyCancelled:
            return false
        case .sessionTaskFailed(let error):
            return (error as NSError).code != NSURLErrorNotConnectedToInternet
        default:
            return false
        }
    }
}
