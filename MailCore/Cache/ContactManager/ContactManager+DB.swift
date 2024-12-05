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
import InfomaniakCoreDB
import RealmSwift

public protocol ContactFetchable {
    /// Case and diacritic insensitive search for a `MergedContact`
    /// - Parameters:
    ///   - string: input string to match against email and name
    ///   - fetchLimit: limit the query by default to limit memory footprint
    /// - Returns: The collection of matching contacts.
    func frozenContacts(matching string: String, fetchLimit: Int?, sorted: ((MergedContact, MergedContact) -> Bool)?)
        -> any Collection<MergedContact>
    func frozenContactsAsync(matching string: String, fetchLimit: Int?, sorted: ((MergedContact, MergedContact) -> Bool)?) async
        -> any Collection<MergedContact>

    /// Case and diacritic insensitive search for a `GroupContact`
    /// - Parameters:
    ///   - string: input string to match against email and name
    ///   - fetchLimit: limit the query by default to limit memory footprint
    /// - Returns: The collection of matching contacts.
    func frozenGroupContacts(matching string: String, fetchLimit: Int?) -> any Collection<GroupContact>

    /// Case and diacritic insensitive search for a `AddressBookContact`
    /// - Parameters:
    ///   - string: input string to match against email and name
    ///   - fetchLimit: limit the query by default to limit memory footprint
    /// - Returns: The collection of matching contacts.
    func frozenAddressBookContacts(matching string: String, fetchLimit: Int?) -> any Collection<AddressBook>

    /// Get a contact from a given transactionable
    func getContact(for correspondent: any Correspondent, transactionable: Transactionable) -> MergedContact?

    /// Get a contact from shared contact manager
    func getContact(for correspondent: any Correspondent) -> MergedContact?
    func addressBook(with id: Int) -> AddressBook?
    func addContact(recipient: Recipient) async throws

    /// Get a contact from group contact (categories)
    func getContacts(with groupContactId: Int) -> [MergedContact]

    /// Get a contact from adressbook
    func getContacts(for addressbookId: Int) -> [MergedContact]
}

public extension ContactManager {
    /// Both *case* insensitive __and__ *diacritic* (accents) insensitive
    static let searchContactInsensitivePredicate = "name contains[cd] %@ OR email contains[cd] %@"
    static let searchGroupContactInsensitivePredicate = "name contains[cd] %@"

    /// Making sure, that by default, we do not overflow memory with too much contacts
    private static let contactFetchLimit = 120

    /// Case and diacritic insensitive search for a `MergedContact`
    /// - Parameters:
    ///   - string: input string to match against email and name
    ///   - fetchLimit: limit the query by default to limit memory footprint
    /// - Returns: The collection of matching contacts. Frozen.
    func frozenContacts(matching string: String, fetchLimit: Int?,
                        sorted: ((MergedContact, MergedContact) -> Bool)?) -> any Collection<MergedContact> {
        var lazyResults = fetchResults(ofType: MergedContact.self) { partial in
            partial
        }
        lazyResults = lazyResults
            .filter(Self.searchContactInsensitivePredicate, string, string)
            .freeze()

        var sortedIfNecessary: any Collection<MergedContact> = lazyResults
        if let sorted {
            sortedIfNecessary = sortedIfNecessary.sorted(by: sorted)
        }

        let finalFetchLimit = fetchLimit ?? Self.contactFetchLimit
        return sortedIfNecessary.prefix(finalFetchLimit)
    }

    /// Async version of fetching frozen contacts
    func frozenContactsAsync(matching string: String, fetchLimit: Int?,
                             sorted: ((MergedContact, MergedContact) -> Bool)?) async -> any Collection<MergedContact> {
        return frozenContacts(matching: string, fetchLimit: fetchLimit, sorted: sorted)
    }

    /// Case and diacritic insensitive search for a `GroupContact`
    /// - Parameters:
    ///   - string: input string to match against email and name
    ///   - fetchLimit: limit the query by default to limit memory footprint
    /// - Returns: The collection of matching contacts. Frozen.
    func frozenGroupContacts(matching string: String, fetchLimit: Int?) -> any Collection<GroupContact> {
        var lazyResults = fetchResults(ofType: GroupContact.self) { partial in
            partial
        }
        lazyResults = lazyResults
            .filter(Self.searchGroupContactInsensitivePredicate, string, string)
            .freeze()

        let fetchLimit = min(lazyResults.count, fetchLimit ?? Self.contactFetchLimit)

        let limitedResults = lazyResults[0 ..< fetchLimit]
        return limitedResults
    }

    /// Case and diacritic insensitive search for a `AddressBookContact`
    /// - Parameters:
    ///   - string: input string to match against email and name
    ///   - fetchLimit: limit the query by default to limit memory footprint
    /// - Returns: The collection of matching contacts.
    func frozenAddressBookContacts(matching string: String, fetchLimit: Int?) -> any Collection<AddressBook> {
        var lazyResults = fetchResults(ofType: AddressBook.self) { partial in
            partial
        }
        lazyResults = lazyResults
            .filter(Self.searchGroupContactInsensitivePredicate, string, string)
            .freeze()

        let fetchLimit = min(lazyResults.count, fetchLimit ?? Self.contactFetchLimit)

        let limitedResults = lazyResults[0 ..< fetchLimit]
        return limitedResults
    }

    func getContact(for correspondent: any Correspondent) -> MergedContact? {
        getContact(for: correspondent, transactionable: self)
    }

    func getContact(for correspondent: any Correspondent, transactionable: Transactionable) -> MergedContact? {
        transactionable.fetchObject(ofType: MergedContact.self) { partial in
            let matched = partial.where { $0.email == correspondent.email }
            let result = matched.filter("name ==[c] %@", correspondent.name).first ?? matched.first
            return result
        }
    }

    func getContacts(with groupContactId: Int) -> [MergedContact] {
        // TODO: To implement
        let frozenContacts = fetchResults(ofType: MergedContact.self) { partial in
            partial
                .where { $0.groupContactId == [groupContactId] }
        }
        return Array(frozenContacts.freezeIfNeeded())
    }

    func getContacts(for addressbookId: Int) -> [MergedContact] {
        let contacts = fetchResults(ofType: MergedContact.self) { partial in
            partial
                .where { $0.remoteAddressBookId == addressbookId }
        }

        return Array(contacts.freezeIfNeeded())
    }

    func addressBook(with id: Int) -> AddressBook? {
        fetchObject(ofType: AddressBook.self, forPrimaryKey: id)
    }

    private func getDefaultAddressBook() -> AddressBook? {
        fetchObject(ofType: AddressBook.self) { partial in
            partial.where { $0.isDefault == true }.first
        }
    }

    func addContact(recipient: Recipient) async throws {
        guard let addressBook = getDefaultAddressBook() else { throw MailError.addressBookNotFound }

        let contactId = try await apiFetcher.addContact(recipient, to: addressBook)
        let contacts = try await apiFetcher.contacts()

        guard let newContact = contacts.first(where: { $0.id == String(contactId) }) else { throw MailError.contactNotFound }

        let mergedContact = MergedContact(email: recipient.email, local: nil, remote: newContact)

        try writeTransaction { writableRealm in
            writableRealm.add(mergedContact, update: .modified)
        }
    }
}
