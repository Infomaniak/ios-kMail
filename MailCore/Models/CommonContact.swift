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

public enum CommonContactBuilder {
    case recipient(recipient: Recipient, contextMailboxManager: MailboxManager)
    case user(user: UserProfile)
    case contact(contact: CommonContact)
    case emptyContact
}

/// Creating a CommonContact is expensive, relying on a cache to reduce hangs
public enum CommonContactCache {
    static let cache = NSCache<NSString, CommonContact>()

    /// Get a contact from cache if any or nil
    public static func getContactFromCache(contactBuilder: CommonContactBuilder) -> CommonContact? {
        let key: NSString
        switch contactBuilder {
        case .recipient(let recipient, _):
            key = recipient.id as NSString
        case .user(let user):
            key = "\(user.id)" as NSString
        case .contact(let contact):
            return contact
        case .emptyContact:
            return CommonContact.emptyContact
        }

        return cache.object(forKey: key)
    }

    /// Get a contact from cache or build it
    public static func getOrCreateContact(contactBuilder: CommonContactBuilder) -> CommonContact {
        let contact: CommonContact
        let key: NSString

        switch contactBuilder {
        case .recipient(let recipient, let contextMailboxManager):
            key = recipient.id as NSString
            contact = getOrCreateContact(recipient: recipient, contextMailboxManager: contextMailboxManager, key: key)
        case .user(let user):
            key = "\(user.id)" as NSString
            contact = getOrCreateContact(user: user, key: key)
        case .contact(let wrappedContact):
            key = "\(wrappedContact.id)" as NSString
            contact = wrappedContact
        case .emptyContact:
            contact = CommonContact.emptyContact
            key = "\(contact.id)" as NSString
        }

        cache.setObject(contact, forKey: key)
        return contact
    }

    private static func getOrCreateContact(user: UserProfile, key: NSString) -> CommonContact {
        guard let contact = CommonContactCache.cache.object(forKey: key) else {
            return CommonContact(user: user)
        }

        return contact
    }

    private static func getOrCreateContact(recipient: Recipient,
                                           contextMailboxManager: MailboxManager,
                                           key: NSString) -> CommonContact {
        guard let contact = CommonContactCache.cache.object(forKey: key) else {
            return CommonContact(recipient: recipient, contextMailboxManager: contextMailboxManager)
        }

        return contact
    }
}

public final class CommonContact: Identifiable {
    /// Empty contact is a singleton
    public static let emptyContact = CommonContact()

    public let id: Int

    public let fullName: String
    public let email: String
    public let avatarImageRequest: AvatarImageRequest
    public let color: UIColor

    static func from(contactBuilder: CommonContactBuilder) -> CommonContact {
        switch contactBuilder {
        case .recipient(let recipient, let contextMailboxManager):
            CommonContact(recipient: recipient, contextMailboxManager: contextMailboxManager)
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

    /// Init form a `Recipient` in the context of a mailbox
    init(recipient: Recipient, contextMailboxManager: MailboxManager) {
//        assert(!Foundation.Thread.isMainThread, "Do not call this init from main actor, too costly")

        email = recipient.email
        id = recipient.id.hashValue

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
            let mainViewRealm = contextMailboxManager.contactManager.getRealm()
            let contact = contextMailboxManager.contactManager.getContact(for: recipient, realm: mainViewRealm)
            fullName = contact?.name ?? (recipient.name.isEmpty ? recipient.email : recipient.name)
            color = contact?.color ?? UIColor.backgroundColor(from: email.hash, with: UIConstants.avatarColors)
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
