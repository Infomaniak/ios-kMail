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
import InfomaniakCore
import MailResources

public extension ApiError {
    static let apiMessageNotFound = HandledError(code: .localError(MailApiErrorCode.mailMessageNotFound),
                                                 localizedMessage: MailResourcesStrings.Localizable
                                                     .errorMessageNotFound,
                                                 shouldDisplay: true)
}

public extension IKErrorRegistry {
    static func instantiateForMail() -> IKErrorRegistry {
        IKErrorRegistry(
            unknownHandledError: HandledError(
                code: .unknown,
                localizedMessage: MailResourcesStrings.Localizable.errorUnknown,
                shouldDisplay: true
            ),
            unknownApiHandledError: HandledError(
                code: .unknownApiError,
                localizedMessage: MailResourcesStrings.Localizable.errorUnknown,
                shouldDisplay: true
            ),
            serverHandledError: HandledError(
                code: .serverError,
                localizedMessage: MailResourcesStrings.Localizable.errorUnknown,
                shouldDisplay: true
            ),
            networkHandledError: HandledError(
                code: .localError("noConnection"),
                localizedMessage: MailResourcesStrings.Localizable.noConnection,
                shouldDisplay: true
            ),
            apiHandledErrors: [
                ApiError.apiMessageNotFound
            ]
        )
    }
}
