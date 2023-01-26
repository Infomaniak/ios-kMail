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
import MailResources

extension ApiError: CustomStringConvertible {}

public enum MailError: LocalizedError {
    case apiError(ApiError)
    case serverError(statusCode: Int)
    case noToken
    case resourceError
    case unknownError
    case unknownToken
    case noMailbox
    case folderNotFound
    case addressBookNotFound
    case contactNotFound
    case attachmentsSizeLimitReached

    public var errorDescription: String? {
        switch self {
        case .apiError(let apiError):
            if let code = ApiErrorCode(rawValue: apiError.code) {
                return code.localizedDescription
            }
            return apiError.description
        case .noToken:
            return "No API token"
        case .resourceError:
            return "Resource error"
        case .unknownError:
            return "Unknown error"
        case .serverError:
            return "Server error"
        case .unknownToken:
            return "Unknown token"
        case .noMailbox:
            return "No Mailbox"
        case .folderNotFound:
            return "Folder not found"
        case .addressBookNotFound:
            return "Address Book not found"
        case .contactNotFound:
            return "Contact not found"
        case .attachmentsSizeLimitReached:
            return MailResourcesStrings.Localizable.attachmentFileLimitReached
        }
    }
}
