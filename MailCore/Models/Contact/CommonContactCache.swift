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
import InfomaniakDI

/// A standard cache for `CommonContact`, used by DI
public typealias ContactCache = NSCache<NSNumber, CommonContact>

/// Creating a `CommonContact` is expensive, relying on a cache to reduce hangs
public enum CommonContactCache {
    /// The underlying standard cache
    @LazyInjectService private static var cache: ContactCache

    /// Get a contact from cache if any or nil
    public static func getContactFromCache(contactConfiguration: ContactConfiguration) -> CommonContact? {
        let key = contactConfiguration.cacheKey
        return cache.object(forKey: key)
    }

    /// Get a contact from cache or build it
    public static func getOrCreateContact(contactConfiguration: ContactConfiguration) -> CommonContact {
        let contact: CommonContact
        let key = contactConfiguration.cacheKey

        switch contactConfiguration {
        case .recipient(let recipient, let contextMailboxManager):
            contact = getOrCreateContact(recipient: recipient, contextMailboxManager: contextMailboxManager, key: key)
        case .user(let user):
            contact = getOrCreateContact(user: user, key: key)
        case .contact(let wrappedContact):
            contact = wrappedContact
        case .emptyContact:
            contact = CommonContact.emptyContact
        }

        cache.setObject(contact, forKey: key)
        return contact
    }

    private static func getOrCreateContact(user: UserProfile, key: NSNumber) -> CommonContact {
        guard let contact = CommonContactCache.cache.object(forKey: key) else {
            return CommonContact(user: user)
        }

        return contact
    }

    private static func getOrCreateContact(recipient: Recipient,
                                           contextMailboxManager: MailboxManager,
                                           key: NSNumber) -> CommonContact {
        guard let contact = CommonContactCache.cache.object(forKey: key) else {
            return CommonContact(recipient: recipient, contextMailboxManager: contextMailboxManager)
        }

        return contact
    }
}
