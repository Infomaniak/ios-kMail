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
        guard let error = error as NSError?,
              error.domain == "invalid_grant" else {
            // Couldn't refresh the token, keep the old token and fetch it later. Maybe because of bad network ?
            SentrySDK
                .addBreadcrumb(oldToken.generateBreadcrumb(level: .error,
                                                           message: "Refreshing token failed - Other \(error.debugDescription)"))
            return .failure(error ?? MailError.unknownError)
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
            self.networkLoginService.refreshToken(token: credential) { token, error in
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
