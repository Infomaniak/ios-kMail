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

import Alamofire
import Foundation
import InfomaniakCore
import InfomaniakDI
import InfomaniakLogin
import Sentry
import UIKit

public extension ApiFetcher {
    convenience init(token: ApiToken, delegate: RefreshTokenDelegate) {
        self.init()
        createAuthenticatedSession(token,
                                   authenticator: SyncedAuthenticator(refreshTokenDelegate: delegate),
                                   additionalAdapters: [RequestContextIdAdaptor(), UserAgentAdapter()])
    }
}

public final class MailApiFetcher: ApiFetcher, MailApiFetchable {
    public static let clientId = "E90BC22D-67A8-452C-BE93-28DA33588CA4"

    /// All status except 401 are handled by our code, 401 status is handled by Alamofire's Authenticator code
    private lazy var handledHttpStatus: Set<Int> = {
        var allStatus = Set(200 ... 500)
        allStatus.remove(401)
        return allStatus
    }()

    override public func perform<T: Decodable>(
        request: DataRequest,
        decoder: JSONDecoder = ApiFetcher.decoder
    ) async throws -> (data: T, responseAt: Int?) {
        do {
            return try await super.perform(request: request.validate(statusCode: handledHttpStatus))
        } catch InfomaniakError.apiError(let apiError) {
            throw MailApiError.mailApiErrorWithFallback(apiErrorCode: apiError.code)
        } catch InfomaniakError.serverError(statusCode: let statusCode) {
            throw MailServerError(httpStatus: statusCode)
        } catch {
            if let afError = error.asAFError {
                if case .responseSerializationFailed(let reason) = afError,
                   case .decodingFailed(let error) = reason {
                    var rawJson = "No data"
                    if let data = request.data,
                       let stringData = String(data: data, encoding: .utf8) {
                        rawJson = stringData
                    }

                    SentrySDK.capture(error: error) { scope in
                        scope.setExtras(["Request URL": request.request?.url?.absoluteString ?? "No URL",
                                         "Request Id": request.request?
                                             .value(forHTTPHeaderField: RequestContextIdAdaptor.requestContextIdHeader) ??
                                             "No request Id",
                                         "Decoded type": String(describing: T.self),
                                         "Raw JSON": rawJson])
                    }
                } else if case .sessionTaskFailed(let error) = afError,
                          (error as NSError).code == NSURLErrorNotConnectedToInternet {
                    throw MailError.noConnection
                }

                throw AFErrorWithContext(request: request, afError: afError)
            } else {
                throw error
            }
        }
    }
}
