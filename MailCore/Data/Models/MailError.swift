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

public struct MailError: Error, Equatable {
    public enum MailErrorType: String, Codable {
        case localError
        case networkError
        case serverError
    }

    public let type: MailErrorType
    public let code: String
    public var localizedDescription: String

    private init(type: MailErrorType, code: String, localizedString: String = "Generic error") {
        self.type = type
        self.code = code
        localizedDescription = localizedString
    }

    public static let refreshToken = MailError(type: .serverError, code: "refreshToken")
    public static let unknownToken = MailError(type: .localError, code: "unknownToken")
    public static let localError = MailError(type: .localError, code: "localError")
    public static let serverError = MailError(type: .serverError, code: "serverError")
    public static let noMailbox = MailError(type: .serverError, code: "no_mailbox")

    public static let unknownError = MailError(type: .localError, code: "unknownError")

    private static let allErrors: [MailError] = []

    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    public init(apiErrorCode: String) {
        if let error = MailError.allErrors.first(where: { $0.type == .serverError && $0.code == apiErrorCode }) {
            self = error
        } else {
            self = .serverError
        }
    }

    public init(apiError: ApiError) {
        if let error = MailError.allErrors.first(where: { $0.type == .serverError && $0.code == apiError.code }) {
            self = error
        } else {
            self = .serverError
        }
    }

    static func from(realmData: Data) -> MailError {
        if let error = try? decoder.decode(MailError.self, from: realmData) {
            return error
        } else {
            return .unknownError
        }
    }

    public static func == (lhs: MailError, rhs: MailError) -> Bool {
        return lhs.code == rhs.code
    }
}

extension MailError: LocalizedError {
    public var errorDescription: String? {
        return localizedDescription
    }
}

extension MailError: Codable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(MailErrorType.self, forKey: .type)
        code = try values.decode(String.self, forKey: .code)
        localizedDescription = MailError.unknownError.localizedDescription
        if let errorDescription = MailError.allErrors.first(where: { $0.type == type && $0.code == code })?.localizedDescription {
            localizedDescription = errorDescription
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(code, forKey: .code)
    }

    enum CodingKeys: String, CodingKey {
        case type
        case code
    }
}
