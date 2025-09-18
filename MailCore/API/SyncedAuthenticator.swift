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
import InfomaniakLogin
import Sentry

public extension ApiToken {
    var isInfinite: Bool {
        expirationDate == nil
    }

    var metadata: [String: Any] {
        [
            "User id": userId,
            "Expiration date": expirationDate?.timeIntervalSince1970 ?? "infinite",
            "Access Token": truncatedAccessToken,
            "Refresh Token": truncatedRefreshToken
        ]
    }
}

final class SyncedAuthenticator: OAuthAuthenticator {
    @LazyInjectService var keychainHelper: KeychainHelper
    @LazyInjectService var tokenStore: TokenStore
    @LazyInjectService var networkLoginService: InfomaniakNetworkLoginable

    func handleFailedRefreshingToken(oldToken: ApiToken,
                                     newToken: ApiToken?,
                                     error: Error?) -> Result<OAuthAuthenticator.Credential, Error> {
        guard let error else {
            // Couldn't refresh the token, keep the old token and fetch it later. Maybe because of bad network ?
            Log.tokenAuthentication(
                "Refreshing token failed - Other \(error.debugDescription)",
                oldToken: oldToken,
                newToken: newToken,
                level: .error
            )

            return .failure(MailError.unknownError)
        }

        if case .noRefreshToken = (error as? InfomaniakLoginError) {
            // Couldn't refresh the token because we don't have a refresh token
            Log.tokenAuthentication(
                "Refreshing token failed - Cannot refresh infinite token",
                oldToken: oldToken,
                newToken: newToken,
                level: .error
            )

            refreshTokenDelegate?.didFailRefreshToken(oldToken)
            return .failure(error)
        }

        if (error as NSError).domain == "invalid_grant" {
            // Couldn't refresh the token, API says it's invalid
            Log.tokenAuthentication(
                "Refreshing token failed - Invalid grant",
                oldToken: oldToken,
                newToken: newToken,
                level: .error
            )

            refreshTokenDelegate?.didFailRefreshToken(oldToken)
            return .failure(error)
        }

        // Something else happened
        return .failure(error)
    }

    override func refresh(
        _ credential: OAuthAuthenticator.Credential,
        for session: Session,
        completion: @escaping (Result<OAuthAuthenticator.Credential, Error>) -> Void
    ) {
        let storedToken = tokenStore.tokenFor(userId: credential.userId, fetchLocation: .keychain)?.apiToken

        Log.tokenAuthentication(
            "Refreshing token - Starting",
            oldToken: storedToken,
            newToken: credential,
            level: .info
        )

        guard keychainHelper.isKeychainAccessible else {
            Log.tokenAuthentication(
                "Refreshing token failed - Keychain unaccessible",
                oldToken: storedToken,
                newToken: credential,
                level: .error
            )

            completion(.failure(MailError.keychainUnavailable))
            return
        }

        if let storedToken {
            // Someone else refreshed our token and we already have an infinite token
            if storedToken.expirationDate == nil && credential.expirationDate != nil {
                Log.tokenAuthentication(
                    "Refreshing token - Success with local (infinite)",
                    oldToken: storedToken,
                    newToken: credential,
                    level: .info
                )

                completion(.success(storedToken))
                return
            }
            // Someone else refreshed our token and we don't have an infinite token
            if let storedTokenExpirationDate = storedToken.expirationDate,
               let tokenExpirationDate = credential.expirationDate,
               tokenExpirationDate > storedTokenExpirationDate {
                Log.tokenAuthentication(
                    "Refreshing token - Success with local",
                    oldToken: storedToken,
                    newToken: credential,
                    level: .info
                )

                completion(.success(storedToken))
                return
            }
        }

        // It is necessary that the app stays awake while we refresh the token
        let expiringActivity = ExpiringActivity()
        expiringActivity.start()
        networkLoginService.refreshToken(token: credential) { result in
            switch result {
            case .success(let token):
                // New token has been fetched correctly
                Log.tokenAuthentication(
                    "Refreshing token - Success with remote",
                    oldToken: credential,
                    newToken: token,
                    level: .info
                )

                self.refreshTokenDelegate?.didUpdateToken(newToken: token, oldToken: credential)
                completion(.success(token))
            case .failure(let error):
                completion(self.handleFailedRefreshingToken(oldToken: credential, newToken: nil, error: error))
            }
            expiringActivity.endAll()
        }
    }
}
