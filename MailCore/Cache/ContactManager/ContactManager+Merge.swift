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
    func merge(localInto remote: [InfomaniakContact]) async {
        // Make sure the base propagates back the changes
        defer {
            DDLogInfo("Done merging remote and local contacts, refreshing DB…")
            getRealm().refresh()
        }

        // index remote account per email
        var remoteContactsByEmail = [String: InfomaniakContact]()
        for contact in remote {
            let emails = contact.emails
            for mail in emails {
                remoteContactsByEmail[mail] = contact
            }
        }

        // Insert all the local contacts, while merging them with the remote version
        let remainingContacts = await insertLocalContactsInDBMerging(remote: remoteContactsByEmail)

        // Insert remaining remote contacts in db
        insertContactsInDB(remainingContacts)
    }

    // Insert Contacts indexed by email in base without check
    private func insertContactsInDB(_ input: [String: InfomaniakContact]) {
        for (email, contact) in input {
            guard !Task.isCancelled else {
                break
            }

            // insert reminder of remote contacts
            guard let mergedContact = MergedContact(email: email, local: nil, remote: contact) else {
                return
            }

            let realm = getRealm()
            try? realm.safeWrite {
                realm.add(mergedContact, update: .modified)
            }
        }
    }

    /// Merge local and remote contacts, insert them in contact database.
    /// - Parameter remote: all the remote Infomaniak contacts, indexed by email
    /// - Returns: The remaining remote contacts without a local version, indexed by email
    private func insertLocalContactsInDBMerging(remote input: [String: InfomaniakContact]) async -> [String: InfomaniakContact] {
        var output = input

        await localContactsHelper.enumerateContacts { localContact, stop in
            // For each email of a specific contact
            for cnEmail in localContact.emailAddresses {
                if Task.isCancelled {
                    stop.pointee = true
                    return
                }

                let email = String(cnEmail.value)

                // lookup matching remote contact for current email
                let remoteContact = input[email]

                // Create DB object
                guard let mergedContact = MergedContact(email: email, local: localContact, remote: remoteContact) else {
                    return
                }

                // Remove email from lookup table
                output.removeValue(forKey: email)

                // Store result
                let realm = self.getRealm()
                try? realm.safeWrite {
                    realm.add(mergedContact, update: .modified)
                }
            }
        }

        return output
    }

    /// Making sure only one update task is running or return
    func uniqueMergeLocalTask(_ apiFetcher: MailApiFetcher) async {
        // We do not run an update of contacts in extension mode as we are too resource constrained
        guard !Bundle.main.isExtension else {
            DDLogInfo("Skip updating contacts, we are in extension mode")
            return
        }

        // Unique task running
        guard currentMergeRequest == nil else {
            DDLogInfo("Merging contacts running exiting …")
            return
        }

        DDLogInfo("Will start merging contacts cancelling previous task : \(currentMergeRequest != nil)")
        let updateTask = Task {
            // Fetch remote contacts
            let remoteContacts: [InfomaniakContact]
            if let remote = try? await apiFetcher.contacts() {
                remoteContacts = remote
            } else {
                remoteContacts = []
            }

            // Merge them
            await merge(localInto: remoteContacts)
        }
        currentMergeRequest = updateTask

        // Await for completion
        await updateTask.finish()
        currentMergeRequest = nil
    }
}
