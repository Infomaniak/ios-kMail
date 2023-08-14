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
import Nuke
import UIKit

public struct AvatarImageRequest {
    let imageRequest: ImageRequest?
    let shouldAuthenticate: Bool

    public func authenticatedRequestIfNeeded(token: ApiToken) -> ImageRequest? {
        guard let unauthenticatedImageRequest = imageRequest,
              let unauthenticatedUrlRequest = unauthenticatedImageRequest.urlRequest else {
            return nil
        }

        guard shouldAuthenticate else {
            return unauthenticatedImageRequest
        }

        var authenticatedUrlRequest = unauthenticatedUrlRequest
        authenticatedUrlRequest.addValue(
            "Bearer \(token.accessToken)",
            forHTTPHeaderField: "Authorization"
        )

        return ImageRequest(urlRequest: authenticatedUrlRequest)
    }
}

public struct CommonContact {
    public let fullName: String
    public let email: String
    public let avatarImageRequest: AvatarImageRequest
    public let color: UIColor

    public init(recipient: Recipient, contextMailboxManager: MailboxManager) {
        email = recipient.email

        if recipient.isMe(currentMailboxEmail: contextMailboxManager.mailbox.email) {
            fullName = MailResourcesStrings.Localizable.contactMe
            color = UIColor.backgroundColor(from: email.hash, with: UIConstants.avatarColors)
            if recipient.isCurrentUser(currentAccountEmail: contextMailboxManager.account.user.email),
               let avatarURL = URL(string: contextMailboxManager.account.user.avatar) {
                avatarImageRequest = AvatarImageRequest(imageRequest: ImageRequest(url: avatarURL), shouldAuthenticate: false)
            } else {
                avatarImageRequest = AvatarImageRequest(imageRequest: nil, shouldAuthenticate: false)
            }
        } else {
            let contact = contextMailboxManager.contactManager.getContact(for: recipient)
            fullName = contact?.name ?? (recipient.name.isEmpty ? recipient.email : recipient.name)
            color = contact?.color ?? UIColor.backgroundColor(from: email.hash, with: UIConstants.avatarColors)
            avatarImageRequest = AvatarImageRequest(imageRequest: contact?.avatarImageRequest, shouldAuthenticate: true)
        }
    }

    public init(user: UserProfile) {
        fullName = user.displayName
        email = user.email
        color = UIColor.backgroundColor(from: user.id, with: UIConstants.avatarColors)
        if let avatarURL = URL(string: user.avatar) {
            avatarImageRequest = AvatarImageRequest(imageRequest: ImageRequest(url: avatarURL), shouldAuthenticate: false)
        } else {
            avatarImageRequest = AvatarImageRequest(imageRequest: nil, shouldAuthenticate: false)
        }
    }
    
    /// A `CommonContact` that represents no-one.
    public static func emptyContact(contextMailboxManager: MailboxManager) -> CommonContact {
        CommonContact(recipient: Recipient(email: "", name: ""), contextMailboxManager: contextMailboxManager)
    }
}

extension CommonContact: Equatable {
    public static func == (lhs: CommonContact, rhs: CommonContact) -> Bool {
        return lhs.fullName == rhs.fullName && lhs.email == rhs.email
    }
}
