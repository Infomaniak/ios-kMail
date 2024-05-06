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

final class SyncedAuthenticator: OAuthAuthenticator {
    @LazyInjectService var keychainHelper: KeychainHelper
    @LazyInjectService var tokenStore: TokenStore
    @LazyInjectService var networkLoginService: InfomaniakNetworkLoginable

    func handleFailedRefreshingToken(oldToken: ApiToken, error: Error?) -> Result<OAuthAuthenticator.Credential, Error> {
        guard let error else {
            // Couldn't refresh the token, keep the old token and fetch it later. Maybe because of bad network ?
            SentrySDK
                .addBreadcrumb(oldToken.generateBreadcrumb(level: .error,
                                                           message: "Refreshing token failed - Other \(error.debugDescription)"))
            return .failure(MailError.unknownError)
        }

        if case .noRefreshToken = (error as? InfomaniakLoginError) {
            // Couldn't refresh the token because we don't have a refresh token
            SentrySDK
                .addBreadcrumb(oldToken.generateBreadcrumb(level: .error,
                                                           message: "Refreshing token failed - Cannot refresh infinite token"))
            refreshTokenDelegate?.didFailRefreshToken(oldToken)
            return .failure(error)
        }

        if (error as NSError).domain == "invalid_grant" {
            // Couldn't refresh the token, API says it's invalid
            SentrySDK
                .addBreadcrumb(oldToken.generateBreadcrumb(level: .error,
                                                           message: "Refreshing token failed - Invalid grant"))
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
        SentrySDK.addBreadcrumb((credential as ApiToken).generateBreadcrumb(level: .info, message: "Refreshing token - Starting"))

        guard keychainHelper.isKeychainAccessible else {
            SentrySDK
                .addBreadcrumb((credential as ApiToken)
                    .generateBreadcrumb(level: .error, message: "Refreshing token failed - Keychain unaccessible"))
            completion(.failure(MailError.noToken))
            return
        }

        if let storedToken = tokenStore.tokenFor(userId: credential.userId, fetchLocation: .keychain) {
            // Someone else refreshed our token and we already have an infinite token
            if storedToken.expirationDate == nil && credential.expirationDate != nil {
                SentrySDK.addBreadcrumb(storedToken.generateBreadcrumb(
                    level: .info,
                    message: "Refreshing token - Success with local (infinite)"
                ))
                completion(.success(storedToken))
                return
            }
            // Someone else refreshed our token and we don't have an infinite token
            if let storedTokenExpirationDate = storedToken.expirationDate,
               let tokenExpirationDate = credential.expirationDate,
               tokenExpirationDate > storedTokenExpirationDate {
                SentrySDK.addBreadcrumb(storedToken.generateBreadcrumb(
                    level: .info,
                    message: "Refreshing token - Success with local"
                ))
                completion(.success(storedToken))
                return
            }
        }

        // It is necessary that the app stays awake while we refresh the token
        let expiringActivity = ExpiringActivity()
        expiringActivity.start()
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
            expiringActivity.endAll()
        }
    }
}
