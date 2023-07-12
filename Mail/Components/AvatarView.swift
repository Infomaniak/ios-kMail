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

import InfomaniakCore
import MailCore
import MailResources
import NukeUI
import SwiftUI

extension ImageRequest {
    func authenticatedRequest(token: ApiToken) -> ImageRequest {
        guard var urlRequest else {
            return self
        }

        urlRequest.addValue(
            "Bearer \(token.accessToken)",
            forHTTPHeaderField: "Authorization"
        )

        return ImageRequest(urlRequest: urlRequest)
    }
}

struct AvatarView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    let avatarDisplayable: AvatarDisplayable
    var size: CGFloat = 28

    var body: some View {
        Group {
            if let currentToken = mailboxManager.apiFetcher.currentToken,
               let avatarImageRequest = avatarDisplayable.avatarImageRequest?.authenticatedRequest(token: currentToken) {
                LazyImage(request: avatarImageRequest) { state in
                    if let image = state.image {
                        ContactImage(image: image, size: size)
                    } else {
                        InitialsView(
                            initials: avatarDisplayable.initials,
                            color: avatarDisplayable.initialsBackgroundColor,
                            size: size
                        )
                    }
                }
            } else {
                InitialsView(initials: avatarDisplayable.initials, color: avatarDisplayable.initialsBackgroundColor, size: size)
            }
        }
        .accessibilityLabel(MailResourcesStrings.Localizable.contentDescriptionUserAvatar)
    }
}
