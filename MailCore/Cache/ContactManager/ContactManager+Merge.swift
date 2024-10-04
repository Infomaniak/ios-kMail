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

import Contacts
import Foundation
import InfomaniakCoreCommonUI
import OSLog

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
    /// This will merge Infomaniak contacts with local device ones in a coherent DB.
    /// Removed contacts from both datasets will be cleaned also.
    public func uniqueUpdateContactDBTask(_ apiFetcher: MailApiFetcher) async {
        // We do not run an update of contacts in extension mode as we are too resource constrained
        guard !Bundle.main.isExtension else {
            Logger.general.info("Skip updating contacts, we are in extension mode")
            return
        }

        // Unique task running
        guard currentMergeRequest == nil else {
            Logger.general.info("UpdateContactDB is running, exiting …")
            return
        }

        Logger.general.info("Will start updating contacts in DB")

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
            Logger.general.info("Done merging remote and local contacts in DB…")
        }

        // Index contacts by id
        var remoteContactsById = [String: InfomaniakContact]()
        for contact in remote {
            let emails = contact.emails
            for email in emails {
                let id = MergedContact.computeId(email: email, name: contact.name)
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

    /// Merge local and remote contacts
    /// - Parameter remoteContacts: all the remote Infomaniak contacts, indexed by id
    /// - Returns: The remaining remote contacts without a local version, indexed by id
    private func mergeLocalAndRemoteContacts(_ remoteContacts: [String: InfomaniakContact]) async -> [String: MergedContact] {
        var notMergedContacts = remoteContacts
        var mergedContacts = [String: MergedContact]()

        await localContactsHelper.enumerateContacts { localContact, stop in
            guard !Task.isCancelled else {
                stop.pointee = true
                return
            }

            for contactEmail in localContact.emailAddresses {
                let email = String(contactEmail.value)

                // lookup matching remote contact for current email
                let id = MergedContact.computeId(email: email, name: localContact.fullName)
                let remoteContact = remoteContacts[id]

                mergedContacts[id] = MergedContact(email: email, local: localContact, remote: remoteContact)
                notMergedContacts.removeValue(forKey: id)
            }
        }

        for notMergedContact in notMergedContacts.values {
            for email in notMergedContact.emails {
                let id = MergedContact.computeId(email: email, name: notMergedContact.name)
                mergedContacts[id] = MergedContact(email: email, local: nil, remote: notMergedContact)
            }
        }

        return mergedContacts
    }

    /// Clean contacts no longer present in remote Infomaniak or local device contacts
    private func removeDeletedContactsFromLocalAndRemote(_ newMergedContacts: [String: MergedContact]) {
        var idsToDelete = [String]()

        // enumerate realm contacts
        let lazyMergedContacts = fetchResults(ofType: MergedContact.self) { partial in
            partial
        }

        var mergedContactIterator = lazyMergedContacts.makeIterator()
        while let mergedContact = mergedContactIterator.next() {
            guard !Task.isCancelled else {
                return
            }

            guard !mergedContact.isInvalidated else {
                continue
            }

            let id = MergedContact.computeId(email: mergedContact.email, name: mergedContact.name)
            if newMergedContacts[id] == nil {
                idsToDelete.append(id)
            }
        }

        guard !Task.isCancelled else {
            return
        }

        guard !idsToDelete.isEmpty else {
            return
        }

        try? writeTransaction { writableRealm in
            for idToDelete in idsToDelete {
                guard let objectToDelete = writableRealm.object(ofType: MergedContact.self, forPrimaryKey: idToDelete) else {
                    continue
                }
                writableRealm.delete(objectToDelete)
            }
        }
    }

    /// Insert Contacts indexed by id in base without check
    private func insertMergedContactsInDB(_ mergedContacts: [String: MergedContact]) {
        guard !Task.isCancelled else {
            return
        }

        try? writeTransaction { writableRealm in
            for mergedContact in mergedContacts.values {
                writableRealm.add(mergedContact, update: .modified)
            }
        }
    }
}
