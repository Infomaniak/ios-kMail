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

import Foundation
import InfomaniakCore
import InfomaniakLogin
import Nuke

public struct AvatarImageRequest {
    let imageRequest: ImageRequest?
    let shouldAuthenticate: Bool

    public func authenticatedRequestIfNeeded(token: ApiToken) -> ImageRequest? {
        guard let imageRequest,
              let urlRequest = imageRequest.urlRequest,
              shouldAuthenticate else {
            return imageRequest
        }

        var authenticatedUrlRequest = urlRequest
        authenticatedUrlRequest.addValue(
            "Bearer \(token.accessToken)",
            forHTTPHeaderField: "Authorization"
        )

        return ImageRequest(urlRequest: authenticatedUrlRequest)
    }
}
