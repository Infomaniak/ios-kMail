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

import CocoaLumberjackSwift
import Contacts
import Foundation
import InfomaniakCore
import RealmSwift
import SwiftRegex

extension CNContact {
    var fullName: String {
        /*
         Workspace API creates a "name" field from the first name and the last name with a space in the middle
         We trim the name in case givenName or familyName is empty
         */
        return (givenName + " " + familyName).trimmingCharacters(in: .whitespaces)
    }
}

extension Recipient: Identifiable {
    public var id: String {
        return name + email
    }
}

public class ContactManager: ObservableObject {
    public class ContactManagerConstants {
        private let fileManager = FileManager.default
        public let rootDocumentsURL: URL
        public let groupDirectoryURL: URL

        init() {
            groupDirectoryURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: AccountManager.appGroup)!
            rootDocumentsURL = groupDirectoryURL.appendingPathComponent("contacts", isDirectory: true)

            try? FileManager.default.createDirectory(
                atPath: rootDocumentsURL.path,
                withIntermediateDirectories: true,
                attributes: nil
            )

            DDLogInfo(
                "App contacts working path is: \(fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.absoluteString ?? "")"
            )
            DDLogInfo("Group container path is: \(groupDirectoryURL.absoluteString)")
        }
    }

    public static let constants = ContactManagerConstants()

    let realmConfiguration: Realm.Configuration
    let backgroundRealm: BackgroundRealm
    let apiFetcher: MailApiFetcher

    public init(userId: Int, apiFetcher: MailApiFetcher) {
        self.apiFetcher = apiFetcher
        let realmName = "\(userId).realm"
        realmConfiguration = Realm.Configuration(
            fileURL: ContactManager.constants.rootDocumentsURL.appendingPathComponent(realmName),
            schemaVersion: 2,
            deleteRealmIfMigrationNeeded: true,
            objectTypes: [
                Contact.self,
                AddressBook.self
            ]
        )
        backgroundRealm = BackgroundRealm(configuration: realmConfiguration)
        Task {
            await uniqueMergeContacts()
        }
    }

    public func getRealm() -> Realm {
        do {
            return try Realm(configuration: realmConfiguration)
        } catch {
            // We can't recover from this error but at least we report it correctly on Sentry
            Logging.reportRealmOpeningError(error, realmConfiguration: realmConfiguration)
        }
    }

    private let localContactsHelper = LocalContactsHelper()

    public var mergedContacts = [String: [String: MergedContact]]()
    public var flatMergedContacts = [MergedContact]()

    private var currentMergeRequest: Task<Void, Never>?

    public func fetchContactsAndAddressBooks() async throws {
        do {
            async let addressBooksRequest = apiFetcher.addressBooks().addressbooks
            async let contactsRequest = apiFetcher.contacts()

            let addressBooks = try await addressBooksRequest
            let contacts = try await contactsRequest
            await backgroundRealm.execute { realm in
                try? realm.safeWrite {
                    realm.add(addressBooks, update: .modified)
                    realm.add(contacts, update: .modified)
                }
            }

            await uniqueMergeContacts()
        } catch {
            await uniqueMergeContacts()

            throw error
        }
    }

    private func uniqueMergeContacts() async {
        DDLogInfo("Will start merging contacts cancelling previous task : \(currentMergeRequest != nil)")
        currentMergeRequest?.cancel()
        currentMergeRequest = Task {
            await mergeContacts()
        }

        await currentMergeRequest?.value
        currentMergeRequest = nil
    }

    private func mergeContacts() async {
        var mergeableContacts = [String: [String: (email: String, local: CNContact?, remote: Contact?)]]()

        // Add local contacts
        await localContactsHelper.enumerateContacts { localContact, stop in
            for cnEmail in localContact.emailAddresses {
                let email = String(cnEmail.value)
                let fullName = localContact.fullName
                if var mergeableContact = mergeableContacts[email] {
                    mergeableContact[fullName] = (email: email, local: localContact, remote: nil)
                } else {
                    mergeableContacts[email] = [fullName: (email: email, local: localContact, remote: nil)]
                }
            }

            if Task.isCancelled {
                stop.pointee = true
                return
            }
        }

        // Add remote contacts
        let realm = getRealm()
        let contacts = realm.objects(Contact.self)
        for remoteContact in contacts {
            for email in remoteContact.emails {
                let fullName = remoteContact.name ?? ""
                if var mergeableContact = mergeableContacts[email] {
                    mergeableContact[fullName] = (email: email, local: mergeableContact[fullName]?.local, remote: remoteContact)
                } else {
                    mergeableContacts[email] = [fullName: (email: email, local: nil, remote: remoteContact)]
                }
            }

            if Task.isCancelled {
                return
            }
        }

        // Merge
        var tmpMergedContacts = [String: [String: MergedContact]]()
        for (email, mergeableContactMatch) in mergeableContacts {
            for (fullName, mergeableContact) in mergeableContactMatch {
                if var tmpMergedContact = tmpMergedContacts[email] {
                    tmpMergedContact[fullName] = MergedContact(
                        email: mergeableContact.email,
                        remote: mergeableContact.remote?.freeze(),
                        local: mergeableContact.local
                    )
                } else {
                    tmpMergedContacts[email] = [fullName: MergedContact(
                        email: mergeableContact.email,
                        remote: mergeableContact.remote?.freeze(),
                        local: mergeableContact.local
                    )]
                }

                if Task.isCancelled {
                    return
                }
            }
        }

        flatMergedContacts = tmpMergedContacts.flatMap { $0.value.values }
        mergedContacts = tmpMergedContacts
    }

    public func getRemoteContact(with identifier: String) -> Contact? {
        let realm = getRealm()
        return realm.object(ofType: Contact.self, forPrimaryKey: identifier)
    }

    public func getLocalContact(with identifier: String) async -> CNContact? {
        return try? await localContactsHelper.getContact(with: identifier)
    }

    public func getContact(for recipient: Recipient) -> MergedContact? {
        guard let mergedContact = mergedContacts[recipient.email] else { return nil }

        return mergedContact[recipient.name] ?? mergedContact.values.first
    }

    public func addressBook(with id: Int) -> AddressBook? {
        let realm = getRealm()
        return realm.object(ofType: AddressBook.self, forPrimaryKey: id)
    }

    public func contacts(matching string: String) -> [MergedContact] {
        return flatMergedContacts
            .filter { $0.name.localizedCaseInsensitiveContains(string) || $0.email.localizedCaseInsensitiveContains(string) }
    }

    public func addContact(recipient: Recipient) async throws {
        guard let addressBook = getDefaultAddressBook() else { throw MailError.addressBookNotFound }

        let contactId = try await apiFetcher.addContact(recipient, to: addressBook)
        let contacts = try await apiFetcher.contacts()

        guard let newContact = contacts.first(where: { $0.id == String(contactId) }) else { throw MailError.contactNotFound }

        await backgroundRealm.execute { realm in
            try? realm.safeWrite {
                realm.add(newContact.detached())
            }
        }

        let fullName = newContact.name ?? ""
        if var matchingByNameContact = mergedContacts[recipient.email] {
            if let mergedContact = matchingByNameContact[fullName] {
                mergedContact.remote = newContact
            } else {
                let newMergedContact = MergedContact(email: recipient.email, remote: newContact, local: nil)
                matchingByNameContact[fullName] = newMergedContact
                flatMergedContacts.append(newMergedContact)
            }
        } else {
            let newMergedContact = MergedContact(email: recipient.email, remote: newContact, local: nil)
            mergedContacts[recipient.email] = [fullName: newMergedContact]
            flatMergedContacts.append(newMergedContact)
        }
    }

    public func getDefaultAddressBook() -> AddressBook? {
        let realm = getRealm()
        return realm.objects(AddressBook.self).where { $0.isDefault == true }.first
    }

    /// Delete all contact data cache for user
    /// - Parameters:
    ///   - userId: User ID
    public static func deleteUserContacts(userId: Int) {
        let files = (try? FileManager.default
            .contentsOfDirectory(at: ContactManager.constants.rootDocumentsURL, includingPropertiesForKeys: nil))
        files?.forEach { file in
            if let matches = Regex(pattern: "(\\d+).realm.*")?.firstMatch(in: file.lastPathComponent), matches.count > 1 {
                let fileUserId = matches[1]
                if Int(fileUserId) == userId {
                    DDLogInfo("Deleting file: \(file.lastPathComponent)")
                    try? FileManager.default.removeItem(at: file)
                }
            }
        }
    }
}
