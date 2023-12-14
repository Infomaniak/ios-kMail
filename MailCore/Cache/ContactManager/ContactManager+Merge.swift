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
import InfomaniakCoreUI

extension CNContact {
    var fullName: String {
        /*
         Workspace API creates a "name" field from the first name and the last name with a space in the middle
         We trim the name in case givenName or familyName is empty
         */
        return (givenName + " " + familyName).trimmingCharacters(in: .whitespaces)
    }
}

extension ContactManager {
    // MARK: - Public

    /// Making sure only one update task is running or return
    ///
    /// This will merge Infomaniak contacts with local iPhone ones in a coherent DB.
    /// Removed contacts from both datasets will be cleaned also.
    public func uniqueUpdateContactDBTask(_ apiFetcher: MailApiFetcher) async {
        // We do not run an update of contacts in extension mode as we are too resource constrained
        guard !Bundle.main.isExtension else {
            DDLogInfo("Skip updating contacts, we are in extension mode")
            return
        }

        // Unique task running
        guard currentMergeRequest == nil else {
            DDLogInfo("UpdateContactDB is running, exiting …")
            return
        }

        DDLogInfo("Will start updating contacts in DB")

        // Track background refresh of contacts, and cancel task is system asks to.
        let backgroundTaskTracker = await ApplicationBackgroundTaskTracker(identifier: #function + UUID().uuidString) {
            self.currentMergeRequest?.cancel()
        }

        let updateTask = Task {
            // Fetch remote contacts
            let remoteContacts: [InfomaniakContact]
            if let remote = try? await apiFetcher.contacts() {
                remoteContacts = remote
            } else {
                remoteContacts = []
            }

            // Update DB with them
            await updateContactDB(remoteContacts)
        }
        currentMergeRequest = updateTask

        // Await for completion
        await updateTask.finish()

        // Making sure to terminate BG work tracker
        await backgroundTaskTracker.end()

        // cleanup
        currentMergeRequest = nil
    }

    /// This represents the complete process of maintaining a coherent DB of contacts in realm
    ///
    /// This will merge InfomaniakContact with local iPhone ones in a coherent DB.
    /// Removed contacts from both datasets will be cleaned also
    /// - Parameter remote: a list of remote infomaniak contacts
    func updateContactDB(_ remote: [InfomaniakContact]) async {
        defer {
            DDLogInfo("Done merging remote and local contacts in DB…")
        }

        // index remote account per email
        var remoteContactsByEmail = [String: InfomaniakContact]()
        for contact in remote {
            let emails = contact.emails
            for mail in emails {
                remoteContactsByEmail[mail] = contact
            }
        }

        // Clean contacts no longer present is remote or local iPhone contacts
        removeDeletedContactsFromLocal(andRemote: remoteContactsByEmail)

        // Insert all the local contacts, while merging them with the remote version
        let remainingContacts = await insertLocalContactsInDBMerging(remote: remoteContactsByEmail)

        // Insert remaining remote contacts in db
        insertContactsInDB(remainingContacts)
    }

    // MARK: - Private

    /// Clean contacts no longer present is remote ik or local iPhone contacts
    private func removeDeletedContactsFromLocal(andRemote remote: [String: InfomaniakContact]) {
        var toDelete = [String]()

        // enumerate realm contacts
        let lazyContacts = getRealm()
            .objects(MergedContact.self)

        var contactIterator = lazyContacts.makeIterator()
        while let mergedContact = contactIterator.next() {
            guard !Task.isCancelled else {
                return
            }

            guard !mergedContact.isInvalidated else {
                continue
            }

            let email = mergedContact.email

            let remote = remote[email]
            let local: CNContact?
            if let localContactId = mergedContact.localIdentifier {
                local = try? localContactsHelper.getContact(with: localContactId)
            } else {
                local = nil
            }

            // If contact not in iPhone nor in remote infomaniak, then should be deleted
            if remote == nil && local == nil {
                toDelete.append(email)
            }
        }

        guard !Task.isCancelled else {
            return
        }

        // remove old contacts
        guard !toDelete.isEmpty else {
            return
        }

        let cleanupRealm = getRealm()
        try? cleanupRealm.safeWrite {
            for emailToDelete in toDelete {
                guard let objectToDelete = cleanupRealm.object(ofType: MergedContact.self, forPrimaryKey: emailToDelete) else {
                    continue
                }
                cleanupRealm.delete(objectToDelete)
            }
        }
    }

    /// Merge local and remote contacts, insert them in contact database.
    /// - Parameter remote: all the remote Infomaniak contacts, indexed by email
    /// - Returns: The remaining remote contacts without a local version, indexed by email
    private func insertLocalContactsInDBMerging(remote input: [String: InfomaniakContact]) async -> [String: InfomaniakContact] {
        var output = input

        await localContactsHelper.enumerateContacts { localContact, stop in
            guard !Task.isCancelled else {
                stop.pointee = true
                return
            }

            // Realm to use for this contact. Do not call it outside this block, or it may crash.
            let realm = self.getRealm()
            try? realm.safeWrite {
                // For each email of a specific contact
                for cnEmail in localContact.emailAddresses {
                    let email = String(cnEmail.value)

                    // lookup matching remote contact for current email
                    let remoteContact = input[email]

                    // Create DB object
                    let mergedContact = MergedContact(email: email, local: localContact, remote: remoteContact)

                    // Remove email from lookup table
                    output.removeValue(forKey: email)

                    // Store result
                    realm.add(mergedContact, update: .modified)
                }
            }
        }

        return output
    }

    // Insert Contacts indexed by email in base without check
    private func insertContactsInDB(_ input: [String: InfomaniakContact]) {
        guard !Task.isCancelled else {
            return
        }

        let realm = getRealm()
        try? realm.safeWrite {
            for (email, contact) in input {
                // insert reminder of remote contacts
                let mergedContact = MergedContact(email: email, local: nil, remote: contact)

                realm.add(mergedContact, update: .modified)
            }
        }
    }
}
