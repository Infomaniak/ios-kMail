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

enum MailError: LocalizedError, CustomStringConvertible {
    case apiError(ApiError)
    case serverError(statusCode: Int)
    case noToken
    case resourceError
    case unknownError
    

    var errorDescription: String? {
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
        }
    }

    var description: String {
        switch self {
        case .apiError(let apiError):
            return "MailError.apiError (\(apiError.code))"
        case .noToken:
            return "MailError.noToken"
        case .resourceError:
            return "MailError.resourceError"
        case .unknownError:
            return "MailError.unknownError"
        case .serverError(let statusCode):
            return "MailError.serverError (\(statusCode))"
        }
    }
}
