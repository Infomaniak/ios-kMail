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

import Foundation
import InfomaniakCore
import InfomaniakCoreSwiftUI
import MailResources
import Nuke
import SwiftUI
import UIKit

public final class CommonContact: Identifiable {
    /// Empty contact is a singleton
    public static let emptyContact = CommonContact()

    public let id: String

    public let fullName: String
    public let email: String
    public let avatarImageRequest: AvatarImageRequest
    public let color: Color

    /// Empty contact
    private init() {
        let recipient = Recipient(email: "", name: "")
        email = recipient.email
        fullName = recipient.name
        id = recipient.id
        color = Color.backgroundColor(from: recipient.hash, with: UIConstants.avatarColors)
        avatarImageRequest = AvatarImageRequest(imageRequest: nil, shouldAuthenticate: true)
    }

    /// Init form a `Correspondent` in the context of a mailbox
    public init(
        correspondent: any Correspondent,
        associatedBimi: Bimi?,
        contextUser: UserProfile,
        contextMailboxManager: MailboxManager
    ) {
        email = correspondent.email
        id = correspondent.id

        if correspondent.isMe(currentMailboxEmail: contextMailboxManager.mailbox.email) {
            fullName = MailResourcesStrings.Localizable.contactMe
            color = Color.backgroundColor(from: email.hash, with: UIConstants.avatarColors)
            if correspondent.isCurrentUser(currentAccountEmail: contextUser.email),
               let avatarString = contextUser.avatar,
               let avatarURL = URL(string: avatarString) {
                avatarImageRequest = AvatarImageRequest(imageRequest: ImageRequest(url: avatarURL), shouldAuthenticate: false)
            } else {
                avatarImageRequest = AvatarImageRequest(imageRequest: nil, shouldAuthenticate: false)
            }
        } else {
            fullName = correspondent.name.isEmpty ? correspondent.email : correspondent.name
            color = Color.backgroundColor(from: email.hash, with: UIConstants.avatarColors)
            let transactionable = contextMailboxManager.contactManager
            let contactImageRequest = contextMailboxManager.contactManager.getContact(
                for: correspondent,
                transactionable: transactionable
            )?.avatarImageRequest

            if let associatedBimi,
               contactImageRequest == nil && associatedBimi.isCertified && !associatedBimi.svgContent.isEmpty {
                avatarImageRequest = AvatarImageRequest(
                    imageRequest: ImageRequest(url: Endpoint.bimiSvgUrl(bimi: associatedBimi).url),
                    shouldAuthenticate: true
                )
            } else {
                avatarImageRequest = AvatarImageRequest(imageRequest: contactImageRequest, shouldAuthenticate: true)
            }
        }
    }

    /// Init form a `UserProfile`
    init(user: UserProfile) {
        id = "user-\(user.id)"
        fullName = user.displayName
        email = user.email
        color = Color.backgroundColor(from: user.id, with: UIConstants.avatarColors)
        if let avatarString = user.avatar,
           let avatarURL = URL(string: avatarString) {
            avatarImageRequest = AvatarImageRequest(imageRequest: ImageRequest(url: avatarURL), shouldAuthenticate: false)
        } else {
            avatarImageRequest = AvatarImageRequest(imageRequest: nil, shouldAuthenticate: false)
        }
    }
}

extension CommonContact: Equatable {
    public static func == (lhs: CommonContact, rhs: CommonContact) -> Bool {
        return lhs.fullName == rhs.fullName && lhs.email == rhs.email
    }
}
