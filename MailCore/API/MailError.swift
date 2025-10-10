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

import Alamofire
import Foundation
import InfomaniakCore
import MailResources

extension ApiError: @retroactive CustomStringConvertible {}

public class AFErrorWithContext: MailError, CustomStringConvertible {
    public let request: DataRequest
    public let afError: AFError

    init(request: DataRequest, afError: AFError) {
        self.request = request
        self.afError = afError
        super.init(code: "afErrorWithContext", shouldDisplay: false)
    }

    public var description: String {
        return afError.localizedDescription
    }
}

public class MailError: LocalizedError, Encodable, ErrorWithCode {
    public let code: String
    public let errorDescription: String?
    public let shouldDisplay: Bool

    init(code: String,
         localizedDescription: String = MailResourcesStrings.Localizable.errorUnknown,
         shouldDisplay: Bool = false) {
        self.code = code
        errorDescription = localizedDescription
        self.shouldDisplay = shouldDisplay
    }

    public static let unknownError = MailError(code: "unknownError", shouldDisplay: true)
    public static let noToken = MailError(
        code: "noToken",
        localizedDescription: MailResourcesStrings.Localizable.refreshTokenError,
        shouldDisplay: true
    )
    public static let keychainUnavailable = MailError(code: "keychainUnavailable", shouldDisplay: false)
    public static let resourceError = MailError(code: "resourceError", shouldDisplay: true)
    public static let unknownToken = MailError(code: "unknownToken", shouldDisplay: true)
    public static let noMailbox = MailError(code: "noMailbox")
    public static let folderNotFound = MailError(code: "folderNotFound",
                                                 localizedDescription: MailResourcesStrings.Localizable.errorFolderNotFound,
                                                 shouldDisplay: true)
    public static let addressBookNotFound = MailError(code: "addressBookNotFound", shouldDisplay: true)
    public static let contactNotFound = MailError(code: "contactNotFound", shouldDisplay: true)
    public static let localMessageNotFound = MailError(code: "messageNotFound",
                                                       localizedDescription: MailResourcesStrings.Localizable
                                                           .errorMessageNotFound,
                                                       shouldDisplay: true)
    public static let attachmentsSizeLimitReached = MailError(code: "attachmentsSizeLimitReached",
                                                              localizedDescription: MailResourcesStrings.Localizable
                                                                  .attachmentFileLimitReached,
                                                              shouldDisplay: true)
    public static let threadHasNoMessageInFolder = MailError(code: "threadHasNoMessageInFolder")

    public static let noConnection = MailError(code: "noConnection",
                                               localizedDescription: MailResourcesStrings.Localizable.noConnection,
                                               shouldDisplay: true)

    /// After an update from the server we are still without a default signature
    public static let defaultSignatureMissing = MailError(code: "defaultSignatureMissing")

    public static let noCalendarAttachmentFound = MailError(code: "noCalendarAttachmentFound")

    public static let tooShortScheduleDelay = MailError(code: "tooShortScheduleDelay")

    public static let missingSnoozeUUID = MailError(
        code: "missingSnoozeUUID",
        localizedDescription: MailResourcesStrings.Localizable.errorMessageNotSnoozed,
        shouldDisplay: true
    )
}

extension MailError: Identifiable {
    public var id: String {
        return code
    }
}

extension MailError: Equatable {
    public static func == (lhs: MailError, rhs: MailError) -> Bool {
        return lhs.code == rhs.code
    }
}

public class MailServerError: MailError {
    let httpStatus: Int
    init(httpStatus: Int) {
        self.httpStatus = httpStatus
        super.init(code: "serverError")
    }
}
