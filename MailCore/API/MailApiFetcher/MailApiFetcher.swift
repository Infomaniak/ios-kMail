/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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
import Algorithms
import Foundation
import InfomaniakConcurrency
import InfomaniakCore
import InfomaniakDI
import InfomaniakLogin
import Sentry
import UIKit

public extension ApiFetcher {
    convenience init(token: ApiToken, delegate: RefreshTokenDelegate) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        let formatter = ISO8601DateFormatter()
        formatter.timeZone = .current
        formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(formatter.string(from: date))
        }

        self.init(decoder: decoder, bodyEncoder: encoder)

        createAuthenticatedSession(token,
                                   authenticator: SyncedAuthenticator(refreshTokenDelegate: delegate),
                                   additionalAdapters: [UserAgentAdapter()])
    }
}

public final class MailApiFetcher: ApiFetcher, MailApiFetchable {
    /// All status except 401 are handled by our code, 401 status is handled by Alamofire's Authenticator code
    private lazy var handledHttpStatus: Set<Int> = {
        var allStatus = Set(200 ... 500)
        allStatus.remove(401)
        return allStatus
    }()

    override public func perform<T: Decodable>(request: DataRequest,
                                               overrideDecoder: JSONDecoder? = nil) async throws -> ValidServerResponse<T> {
        do {
            return try await super.perform(
                request: request.validate(statusCode: handledHttpStatus),
                overrideDecoder: overrideDecoder
            )
        } catch InfomaniakError.apiError(let apiError) {
            logError(apiError)
            throw MailApiError.mailApiErrorWithFallback(apiErrorCode: apiError.code)
        } catch InfomaniakError.serverError(statusCode: let statusCode) {
            logError(InfomaniakError.serverError(statusCode: statusCode))
            throw MailServerError(httpStatus: statusCode)
        } catch {
            logError(error)
            if let afError = error.asAFError {
                if case .responseSerializationFailed(let reason) = afError, case .decodingFailed(let error) = reason,
                   let statusCode = request.response?.statusCode, (200 ... 299).contains(statusCode) {
                    var rawJson = "No data"
                    if let data = request.data {
                        rawJson = String(decoding: data, as: UTF8.self)
                    }

                    let requestId = request.response?.value(forHTTPHeaderField: "x-request-id") ?? "No request Id"
                    SentrySDK.capture(error: error) { scope in
                        scope.setExtras(["Request URL": request.request?.url?.absoluteString ?? "No URL",
                                         "Request Id": requestId,
                                         "Decoded type": String(describing: T.self),
                                         "Raw JSON": rawJson])
                    }
                } else if case .sessionTaskFailed(let error) = afError,
                          (error as NSError).code == NSURLErrorNotConnectedToInternet {
                    throw MailError.noConnection

                } else if case .requestAdaptationFailed(let error) = afError,
                          (error as NSError).code == NSURLErrorNotConnectedToInternet {
                    throw MailError.noConnection
                }

                throw AFErrorWithContext(request: request, afError: afError)
            } else {
                logError(error)
                throw error
            }
        }
    }

    /// Create batches of the given values to perform the given request
    /// - Parameters:
    ///   - values: Data to batch
    ///   - chunkSize: Chunk size
    ///   - perform: Request to perform
    /// - Returns: Array of the perform return type
    func batchOver<Input, Output>(values: [Input], chunkSize: Int,
                                  perform: @escaping (([Input]) async throws -> Output?)) async rethrows -> [Output] {
        let chunks = values.chunks(ofCount: chunkSize)
        let responses = try await chunks.asyncMap { chunk in
            try await perform(Array(chunk))
        }
        return responses.compactMap { $0 }
    }
}
