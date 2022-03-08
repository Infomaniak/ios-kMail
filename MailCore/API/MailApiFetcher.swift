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
import InfomaniakLogin
import UIKit

extension ApiFetcher {
    public convenience init(token: ApiToken, delegate: RefreshTokenDelegate) {
        self.init()
        setToken(token, authenticator: SyncedAuthenticator(refreshTokenDelegate: delegate))
    }

    // MARK: - User methods

    func userProfile() async throws -> UserProfile {
        try await perform(request: authenticatedSession.request("\(apiURL)profile?with=avatar,phones,emails")).data
    }

    // MARK: - New request helpers

    func authenticatedRequest(_ endpoint: Endpoint, method: HTTPMethod = .get, parameters: Parameters? = nil) -> DataRequest {
        return authenticatedSession.request(endpoint.url, method: method, parameters: parameters, encoding: JSONEncoding.default)
    }

    func authenticatedRequest<Parameters: Encodable>(_ endpoint: Endpoint, method: HTTPMethod = .get,
                                                     parameters: Parameters? = nil) -> DataRequest {
        return authenticatedSession.request(
            endpoint.url,
            method: method,
            parameters: parameters,
            encoder: JSONParameterEncoder.convertToSnakeCase
        )
    }

    func perform<T: Decodable>(request: DataRequest) async throws -> (data: T, responseAt: Int?) {
        let response = await request.serializingDecodable(
            ApiResponse<T>.self,
            automaticallyCancelling: true,
            decoder: ApiFetcher.decoder
        ).response
        let json = try response.result.get()
        if let result = json.data {
            return (result, json.responseAt)
        } else if let apiError = json.error {
            throw MailError.apiError(apiError)
        } else {
            throw MailError.unknownError
        }
    }
}

public class MailApiFetcher: ApiFetcher {
    public static let clientId = "E90BC22D-67A8-452C-BE93-28DA33588CA4"

    override public init() {
        super.init()
        ApiFetcher.decoder.keyDecodingStrategy = .convertFromSnakeCase
        ApiFetcher.decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - API methods

    public func mailboxes() async throws -> [Mailbox] {
        try await perform(request: authenticatedRequest(.mailbox)).data
    }

    func folders(mailbox: Mailbox) async throws -> [Folder] {
        try await perform(request: authenticatedRequest(.folders(uuid: mailbox.uuid))).data
    }

    func threads(mailbox: Mailbox, folder: Folder, filter: Filter = .all) async throws -> ThreadResult {
        try await perform(request: authenticatedRequest(.threads(uuid: mailbox.uuid, folderId: folder._id, filter: filter == .all ? nil : filter.rawValue))).data
    }
}

class SyncedAuthenticator: OAuthAuthenticator {
    override func refresh(
        _ credential: OAuthAuthenticator.Credential,
        for session: Session,
        completion: @escaping (Result<OAuthAuthenticator.Credential, Error>) -> Void
    ) {
        AccountManager.instance.refreshTokenLockedQueue.async {
            if !KeychainHelper.isKeychainAccessible {
                completion(.failure(MailError.noToken))
                return
            }

            // Maybe someone else refreshed our token
            AccountManager.instance.reloadTokensAndAccounts()
            if let token = AccountManager.instance.getTokenForUserId(credential.userId),
               token.expirationDate > credential.expirationDate {
                completion(.success(token))
                return
            }

            let group = DispatchGroup()
            group.enter()
            var taskIdentifier: UIBackgroundTaskIdentifier = .invalid
            if !Constants.isInExtension {
                // It is absolutely necessary that the app stays awake while we refresh the token
                taskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "Refresh token") {
                    // If we didn't fetch the new token in the given time there is not much we can do apart from hoping that it wasn't revoked
                    if taskIdentifier != .invalid {
                        UIApplication.shared.endBackgroundTask(taskIdentifier)
                        taskIdentifier = .invalid
                    }
                }

                if taskIdentifier == .invalid {
                    // We couldn't request additional time to refresh token maybe try later...
                    completion(.failure(MailError.noToken))
                    return
                }
            }
            InfomaniakLogin.refreshToken(token: credential) { token, error in
                // New token has been fetched correctly
                if let token = token {
                    self.refreshTokenDelegate?.didUpdateToken(newToken: token, oldToken: credential)
                    completion(.success(token))
                } else {
                    // Couldn't refresh the token, API says it's invalid
                    if let error = error as NSError?, error.domain == "invalid_grant" {
                        self.refreshTokenDelegate?.didFailRefreshToken(credential)
                        completion(.failure(error))
                    } else {
                        // Couldn't refresh the token, keep the old token and fetch it later. Maybe because of bad network ?

                        completion(.success(credential))
                    }
                }
                if taskIdentifier != .invalid {
                    UIApplication.shared.endBackgroundTask(taskIdentifier)
                    taskIdentifier = .invalid
                }
                group.leave()
            }
            group.wait()
        }
    }
}

class NetworkRequestRetrier: RequestInterceptor {
    let maxRetry: Int
    private var retriedRequests: [String: Int] = [:]
    let timeout = -1001
    let connectionLost = -1005

    init(maxRetry: Int = 3) {
        self.maxRetry = maxRetry
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
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
        guard let url = url else {
            return
        }
        retriedRequests.removeValue(forKey: url)
    }
}
