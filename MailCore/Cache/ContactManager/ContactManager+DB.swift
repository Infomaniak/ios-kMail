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
import RealmSwift

/// Conforming to `RealmAccessible` to get a standard `.getRealm` function
extension ContactManager: RealmAccessible {}

public extension ContactManager {
    /// Both *case* insensitive __and__ *diacritic* (accents) insensitive
    static let searchContactInsensitivePredicate = "name contains[cd] %@ OR email contains[cd] %@"

    /// Making sure, that by default, we do not overflow memory with too much contacts
    private static let contactFetchLimit = 120

    /// Case and diacritic insensitive search for a `MergedContact`
    /// - Parameters:
    ///   - string: input string to match against email and name
    ///   - fetchLimit: limit the query by default to limit memory footprint
    /// - Returns: The collection of matching contacts.
    func contacts(matching string: String, fetchLimit: Int? = nil) -> [MergedContact] {
        let realm = getRealm()
        let lazyResults = realm
            .objects(MergedContact.self)
            .filter(Self.searchContactInsensitivePredicate, string, string)

        // Use a default value if none provided
        let fetchLimit = fetchLimit ?? Self.contactFetchLimit

        // Iterate a given number of times to emulate a `LIMIT` statement.
        var iterator = lazyResults.makeIterator()
        var results = [MergedContact]()
        for _ in 0 ..< fetchLimit {
            guard let next = iterator.next() else {
                break
            }
            results.append(next)
        }

        return results
    }

    func getContact(for recipient: Recipient, realm: Realm? = nil) -> MergedContact? {
        let realm = realm ?? getRealm()
        let matched = realm.objects(MergedContact.self).where { $0.email == recipient.email }
        return matched.first { $0.name.caseInsensitiveCompare(recipient.name) == .orderedSame } ?? matched.first
    }

    func addressBook(with id: Int) -> AddressBook? {
        let realm = getRealm()
        return realm.object(ofType: AddressBook.self, forPrimaryKey: id)
    }

    private func getDefaultAddressBook() -> AddressBook? {
        let realm = getRealm()
        return realm.objects(AddressBook.self).where { $0.isDefault == true }.first
    }

    func addContact(recipient: Recipient) async throws {
        guard let addressBook = getDefaultAddressBook() else { throw MailError.addressBookNotFound }

        let contactId = try await apiFetcher.addContact(recipient, to: addressBook)
        let contacts = try await apiFetcher.contacts()

        guard let newContact = contacts.first(where: { $0.id == String(contactId) }) else { throw MailError.contactNotFound }

        let mergedContact = MergedContact(email: recipient.email, local: nil, remote: newContact)

        let realm = getRealm()
        try? realm.safeWrite {
            realm.add(mergedContact, update: .modified)
        }
    }
}
