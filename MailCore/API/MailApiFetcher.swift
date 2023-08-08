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
                                   additionalAdapters: [RequestContextIdAdaptor()])
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
                }
                throw AFErrorWithContext(request: request, afError: afError)
            } else {
                throw error
            }
        }
    }
}

final class SyncedAuthenticator: OAuthAuthenticator {
    func handleFailedRefreshingToken(oldToken: ApiToken, error: Error?) -> Result<OAuthAuthenticator.Credential, Error> {
        guard let error = error as NSError?,
              error.domain == "invalid_grant" else {
            // Couldn't refresh the token, keep the old token and fetch it later. Maybe because of bad network ?
            SentrySDK
                .addBreadcrumb(oldToken.generateBreadcrumb(level: .error,
                                                           message: "Refreshing token failed - Other \(error.debugDescription)"))
            return .success(oldToken)
        }

        // Couldn't refresh the token, API says it's invalid
        SentrySDK.addBreadcrumb(oldToken.generateBreadcrumb(level: .error, message: "Refreshing token failed - Invalid grant"))
        refreshTokenDelegate?.didFailRefreshToken(oldToken)
        return .failure(error)
    }

    override func refresh(
        _ credential: OAuthAuthenticator.Credential,
        for session: Session,
        completion: @escaping (Result<OAuthAuthenticator.Credential, Error>) -> Void
    ) {
        @InjectService var keychainHelper: KeychainHelper
        @InjectService var tokenStore: TokenStore
        @InjectService var networkLoginService: InfomaniakNetworkLoginable

        SentrySDK.addBreadcrumb((credential as ApiToken).generateBreadcrumb(level: .info, message: "Refreshing token - Starting"))

        guard keychainHelper.isKeychainAccessible else {
            SentrySDK
                .addBreadcrumb((credential as ApiToken)
                    .generateBreadcrumb(level: .error, message: "Refreshing token failed - Keychain unaccessible"))
            completion(.failure(MailError.noToken))
            return
        }

        // Maybe someone else refreshed our token
        if let token = tokenStore.tokenFor(userId: credential.userId, fetchLocation: .keychain),
           token.expirationDate > credential.expirationDate {
            SentrySDK.addBreadcrumb(token.generateBreadcrumb(level: .info, message: "Refreshing token - Success with local"))
            completion(.success(token))
            return
        }

        // It is absolutely necessary that the app stays awake while we refresh the token
        BackgroundExecutor.executeWithBackgroundTask { endBackgroundTask in
            networkLoginService.refreshToken(token: credential) { token, error in
                // New token has been fetched correctly
                if let token {
                    SentrySDK
                        .addBreadcrumb(token
                            .generateBreadcrumb(level: .info, message: "Refreshing token - Success with remote"))
                    self.refreshTokenDelegate?.didUpdateToken(newToken: token, oldToken: credential)
                    completion(.success(token))
                } else {
                    completion(self.handleFailedRefreshingToken(oldToken: credential, error: error))
                }
                endBackgroundTask()
            }
        } onExpired: {
            SentrySDK
                .addBreadcrumb((credential as ApiToken)
                    .generateBreadcrumb(level: .error, message: "Refreshing token failed - Background task expired"))
            // If we didn't fetch the new token in the given time there is not much we can do apart from hoping that it wasn't
            // revoked
            completion(.failure(MailError.noToken))
        }
    }
}

final class NetworkRequestRetrier: RequestInterceptor {
    let maxRetry: Int
    private var retriedRequests: [String: Int] = [:]
    let timeout = -1001
    let connectionLost = -1005

    init(maxRetry: Int = 3) {
        self.maxRetry = maxRetry
    }

    func retry(
        _ request: Alamofire.Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        guard request.task?.response == nil,
              let url = request.request?.url?.absoluteString else {
            removeCachedUrlRequest(url: request.request?.url?.absoluteString)
            completion(.doNotRetry)
            return
        }

        let errorGenerated = error as NSError
        switch errorGenerated.code {
        case timeout, connectionLost:
            guard let retryCount = retriedRequests[url] else {
                retriedRequests[url] = 1
                completion(.retryWithDelay(0.5))
                return
            }

            if retryCount < maxRetry {
                retriedRequests[url] = retryCount + 1
                completion(.retryWithDelay(0.5))
            } else {
                removeCachedUrlRequest(url: url)
                completion(.doNotRetry)
            }

        default:
            removeCachedUrlRequest(url: url)
            completion(.doNotRetry)
        }
    }

    private func removeCachedUrlRequest(url: String?) {
        guard let url else {
            return
        }
        retriedRequests.removeValue(forKey: url)
    }
}
