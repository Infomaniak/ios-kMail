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
import InfomaniakDI
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

public class MailError: LocalizedError, Encodable {
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

public extension MailError {
    static let unknownError: LocalError = {
        @InjectService var errorRegistry: IKErrorRegistry
        return errorRegistry.unknownError(underlyingError: nil, shouldDisplay: true)
    }()

    static let noToken = LocalError(
        code: "noToken",
        localizedMessage: MailResourcesStrings.Localizable.refreshTokenError,
        shouldDisplay: true
    )
    static let keychainUnavailable = LocalError(code: "keychainUnavailable")
    static let resourceError = LocalError(
        code: "resourceError",
        localizedMessage: MailResourcesStrings.Localizable.errorUnknown,
        shouldDisplay: true
    )
    static let unknownToken = LocalError(
        code: "unknownToken",
        localizedMessage: MailResourcesStrings.Localizable.errorUnknown,
        shouldDisplay: true
    )
    static let noMailbox = LocalError(code: "noMailbox")
    static let folderNotFound = LocalError(code: "folderNotFound",
                                           localizedMessage: MailResourcesStrings.Localizable.errorUnknown,
                                           shouldDisplay: true)
    static let addressBookNotFound = LocalError(code: "addressBookNotFound",
                                                localizedMessage: MailResourcesStrings.Localizable.errorUnknown,
                                                shouldDisplay: true)
    static let contactNotFound = LocalError(
        code: "contactNotFound",
        localizedMessage: MailResourcesStrings.Localizable.errorUnknown,
        shouldDisplay: true
    )
    static let localMessageNotFound = LocalError(code: "messageNotFound",
                                                 localizedMessage: MailResourcesStrings.Localizable.errorMessageNotFound,
                                                 shouldDisplay: true)
    static let attachmentsSizeLimitReached = LocalError(code: "attachmentsSizeLimitReached",
                                                        localizedMessage: MailResourcesStrings.Localizable
                                                            .attachmentFileLimitReached,
                                                        shouldDisplay: true)
    static let threadHasNoMessageInFolder = LocalError(code: "threadHasNoMessageInFolder")

    /// After an update from the server we are still without a default signature
    static let defaultSignatureMissing = LocalError(code: "defaultSignatureMissing")

    static let noCalendarAttachmentFound = LocalError(code: "noCalendarAttachmentFound")

    static let tooShortScheduleDelay = LocalError(code: "tooShortScheduleDelay")

    static let missingSnoozeUUID = LocalError(
        code: "missingSnoozeUUID",
        localizedMessage: MailResourcesStrings.Localizable.errorMessageNotSnoozed,
        shouldDisplay: true
    )
}
