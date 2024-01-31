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

public enum ContactConfiguration: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .correspondent(let recipient, _):
            return ".recipient:\(recipient.name) \(recipient.email)"
        case .user(let user):
            return ".user:\(user.displayName) \(user.email)"
        case .contact(let contact):
            return ".contact:\(contact.fullName) \(contact.email)"
        case .emptyContact:
            return ".emptyContact"
        }
    }

    case correspondent(correspondent: any Correspondent, contextMailboxManager: MailboxManager)
    case user(user: UserProfile)
    case contact(contact: CommonContact)
    case emptyContact

    public func freezeIfNeeded() -> Self {
        switch self {
        case .correspondent(let correspondent, let contextMailboxManager):
            return .correspondent(correspondent: correspondent, contextMailboxManager: contextMailboxManager)
        default:
            return self
        }
    }
}

extension ContactConfiguration {
    /// A stable key to be used with NSCache
    var cacheKey: NSNumber {
        return NSNumber(value: id)
    }
}

extension ContactConfiguration: Identifiable {
    public var id: Int {
        switch self {
        case .correspondent(let correspondent, let contextMailboxManager):
            // One cache entry per correspondent per mailbox
            var hasher = Hasher()
            hasher.combine(correspondent.id)
            hasher.combine(contextMailboxManager.mailbox.id)
            return hasher.finalize()
        case .user(let user):
            return user.id
        case .contact(let wrappedContact):
            return wrappedContact.id
        case .emptyContact:
            return CommonContact.emptyContact.id
        }
    }
}
