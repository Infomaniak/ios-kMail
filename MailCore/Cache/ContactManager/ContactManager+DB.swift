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

public protocol ContactFetchable {
    /// Case and diacritic insensitive search for a `MergedContact`
    /// - Parameters:
    ///   - string: input string to match against email and name
    ///   - fetchLimit: limit the query by default to limit memory footprint
    /// - Returns: The collection of matching contacts.
    func frozenContacts(matching string: String, fetchLimit: Int?) -> [MergedContact]
    func getContact(for recipient: Recipient, realm: Realm?) -> MergedContact?
    func addressBook(with id: Int) -> AddressBook?
    func addContact(recipient: Recipient) async throws
}

public extension ContactManager {
    /// Both *case* insensitive __and__ *diacritic* (accents) insensitive
    static let searchContactInsensitivePredicate = "name contains[cd] %@ OR email contains[cd] %@"

    /// Making sure, that by default, we do not overflow memory with too much contacts
    private static let contactFetchLimit = 120

    /// Case and diacritic insensitive search for a `MergedContact`
    /// - Parameters:
    ///   - string: input string to match against email and name
    ///   - fetchLimit: limit the query by default to limit memory footprint
    /// - Returns: The collection of matching contacts. Frozen.
    func frozenContacts(matching string: String, fetchLimit: Int?) -> [MergedContact] {
        let realm = getRealm()
        let lazyResults = realm
            .objects(MergedContact.self)
            .filter(Self.searchContactInsensitivePredicate, string, string)

        let fetchLimit = min(lazyResults.count, fetchLimit ?? Self.contactFetchLimit)

        let limitedResults = lazyResults[0 ..< fetchLimit]
        return limitedResults.map { $0.freezeIfNeeded() }
    }

    func getContact(for correspondent: any Correspondent, realm: Realm? = nil) -> MergedContact? {
        let realm = realm ?? getRealm()
        let matched = realm.objects(MergedContact.self).where { $0.email == correspondent.email }
        return matched.first { $0.name.caseInsensitiveCompare(correspondent.name) == .orderedSame } ?? matched.first
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
