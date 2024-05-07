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
import InfomaniakDI

/// A standard cache for `CommonContact`, used by DI
public typealias ContactCache = NSCache<NSNumber, CommonContact>

/// Creating a `CommonContact` is expensive, relying on a cache to reduce hangs
public enum CommonContactCache {
    /// Set to false for testing without cache
    private static let cacheEnabled = true

    /// The underlying standard cache
    @LazyInjectService private static var cache: ContactCache

    /// Get a contact from cache if any or nil
    public static func getContactFromCache(contactConfiguration: ContactConfiguration) -> CommonContact? {
        /// cache enabled check
        guard cacheEnabled else {
            return nil
        }

        return cache.object(forKey: contactConfiguration.cacheKey)
    }

    /// Get a contact from cache or build it
    public static func getOrCreateContact(contactConfiguration: ContactConfiguration) -> CommonContact {
        /// Try to fetch the entry from cache
        if let cachedContact = getContactFromCache(contactConfiguration: contactConfiguration) {
            return cachedContact
        }

        let contact: CommonContact
        switch contactConfiguration {
        case .correspondent(let correspondent, let bimi, let contextMailboxManager):
            contact = CommonContact(correspondent: correspondent, associatedBimi: bimi, contextMailboxManager: contextMailboxManager)
        case .user(let user):
            contact = CommonContact(user: user)
        case .contact(let wrappedContact):
            contact = wrappedContact
        case .emptyContact:
            contact = CommonContact.emptyContact
        }

        // Store the object in cache
        cache.setObject(contact, forKey: contactConfiguration.cacheKey)

        return contact
    }
}
