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

public final class CommonContact: Identifiable {
    /// Empty contact is a singleton
    public static let emptyContact = CommonContact()

    public let id: Int

    public let fullName: String
    public let email: String
    public let avatarImageRequest: AvatarImageRequest
    public let color: UIColor

    static func from(contactConfiguration: ContactConfiguration) -> CommonContact {
        switch contactConfiguration {
        case .correspondent(let correspondent, let contextMailboxManager):
            CommonContact(correspondent: correspondent, contextMailboxManager: contextMailboxManager)
        case .user(let user):
            CommonContact(user: user)
        case .contact(let contact):
            contact
        case .emptyContact:
            emptyContact
        }
    }

    /// Empty contact
    private init() {
        let recipient = Recipient(email: "", name: "")
        email = recipient.email
        fullName = recipient.name
        id = recipient.id.hashValue
        color = UIColor.backgroundColor(from: recipient.hash, with: UIConstants.avatarColors)
        avatarImageRequest = AvatarImageRequest(imageRequest: nil, shouldAuthenticate: true)
    }

    /// Init form a `Correspondent` in the context of a mailbox
    init(correspondent: any Correspondent, contextMailboxManager: MailboxManager) {
        email = correspondent.email
        id = correspondent.id.hashValue

        if correspondent.isMe(currentMailboxEmail: contextMailboxManager.mailbox.email) {
            fullName = MailResourcesStrings.Localizable.contactMe
            color = UIColor.backgroundColor(from: email.hash, with: UIConstants.avatarColors)
            if correspondent.isCurrentUser(currentAccountEmail: contextMailboxManager.account.user.email),
               let avatarURL = URL(string: contextMailboxManager.account.user.avatar) {
                avatarImageRequest = AvatarImageRequest(imageRequest: ImageRequest(url: avatarURL), shouldAuthenticate: false)
            } else {
                avatarImageRequest = AvatarImageRequest(imageRequest: nil, shouldAuthenticate: false)
            }
        } else {
            let mainViewRealm = contextMailboxManager.contactManager.getRealm()
            let contact = contextMailboxManager.contactManager.getContact(for: correspondent, realm: mainViewRealm)
            fullName = contact?.name ?? (correspondent.name.isEmpty ? correspondent.email : correspondent.name)
            color = UIColor.backgroundColor(from: email.hash, with: UIConstants.avatarColors)
            avatarImageRequest = AvatarImageRequest(imageRequest: contact?.avatarImageRequest, shouldAuthenticate: true)
        }
    }

    /// Init form a `UserProfile`
    init(user: UserProfile) {
        id = user.id
        fullName = user.displayName
        email = user.email
        color = UIColor.backgroundColor(from: user.id, with: UIConstants.avatarColors)
        if let avatarURL = URL(string: user.avatar) {
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
