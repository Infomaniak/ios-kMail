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
    /// This will merge InfomaniakContact with the local device's ones in a coherent DB.
    /// Removed contacts from both datasets will be cleaned also
    /// - Parameter remote: a list of remote infomaniak contacts
    func updateContactDB(_ remote: [InfomaniakContact]) async {
        defer {
            DDLogInfo("Done merging remote and local contacts in DB…")
        }

        // Index contacts by id
        var remoteContactsById = [Int: InfomaniakContact]()
        for contact in remote {
            let emails = contact.emails
            for email in emails {
                let id = computeContactId(email: email, name: contact.name)
                if let remoteContact = remoteContactsById[id] {
                    if remoteContact.avatar == nil {
                        remoteContactsById[id]?.avatar = contact.avatar
                    }
                } else {
                    remoteContactsById[id] = contact
                }
            }
        }

        let mergedContacts = await mergeLocalAndRemoteContacts(remoteContactsById)
        removeDeletedContactsFromLocalAndRemote(mergedContacts)
        insertMergedContactsInDB(mergedContacts)
    }

    // MARK: - Private

    private func computeContactId(email: String, name: String?) -> Int {
        guard let name, name != email else { return email.hash }
        return email.hash ^ name.hash
    }

    /// Merge local and remote contacts, insert them in contact database.
    /// - Parameter remote: all the remote Infomaniak contacts, indexed by id
    /// - Returns: The remaining remote contacts without a local version, indexed by id
    private func mergeLocalAndRemoteContacts(_ remoteContacts: [Int: InfomaniakContact]) async -> [MergedContact] {
        var notMergedContacts = remoteContacts
        var mergedContacts = [MergedContact]()

        await localContactsHelper.enumerateContacts { localContact, stop in
            guard !Task.isCancelled else {
                stop.pointee = true
                return
            }

            for contactEmail in localContact.emailAddresses {
                let email = String(contactEmail.value)

                // lookup matching remote contact for current email
                let id = self.computeContactId(email: email, name: localContact.fullName)
                let remoteContact = remoteContacts[id]

                mergedContacts.append(MergedContact(email: email, local: localContact, remote: remoteContact))
                notMergedContacts.removeValue(forKey: id)
            }
        }

        for (_, notMergedContact) in notMergedContacts {
            for email in notMergedContact.emails {
                mergedContacts.append(MergedContact(email: email, local: nil, remote: notMergedContact))
            }
        }

        return mergedContacts
    }

    /// Clean contacts no longer present is remote ik or local device contacts
    private func removeDeletedContactsFromLocalAndRemote(_ newMergedContacts: [MergedContact]) {
        var idsToDelete = [Int]()

        // enumerate realm contacts
        let lazyMergedContacts = getRealm().objects(MergedContact.self)

        var mergedContactIterator = lazyMergedContacts.makeIterator()
        while let mergedContact = mergedContactIterator.next() {
            guard !Task.isCancelled else {
                return
            }

            guard !mergedContact.isInvalidated else {
                continue
            }

            let id = computeContactId(email: mergedContact.email, name: mergedContact.name)
            if !newMergedContacts.contains(where: { $0.id == id }) {
                idsToDelete.append(id)
            }
        }

        guard !Task.isCancelled else {
            return
        }

        guard !idsToDelete.isEmpty else {
            return
        }

        let cleanupRealm = getRealm()
        try? cleanupRealm.safeWrite {
            for idToDelete in idsToDelete {
                guard let objectToDelete = cleanupRealm.object(ofType: MergedContact.self, forPrimaryKey: idToDelete) else {
                    continue
                }
                cleanupRealm.delete(objectToDelete)
            }
        }
    }

    // Insert Contacts indexed by id in base without check
    private func insertMergedContactsInDB(_ mergedContacts: [MergedContact]) {
        guard !Task.isCancelled else {
            return
        }

        let realm = getRealm()
        try? realm.safeWrite {
            for mergedContact in mergedContacts {
                realm.add(mergedContact, update: .modified)
            }
        }
    }
}
