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
import MailResources
import RealmSwift

// MARK: - Signatures

public extension MailboxManager {
    func refreshAllSignatures() async throws {
        // Get from API
        let signaturesResult = try await apiFetcher.signatures(mailbox: mailbox)
        let updatedSignatures = Array(signaturesResult.signatures)

        await backgroundRealm.execute { realm in
            let signaturesToDelete: [Signature] // no longer present server side
            let signaturesToUpdate: [Signature] // updated signatures
            let signaturesToAdd: [Signature] // new signatures

            // fetch all local signatures
            let existingSignatures = Array(realm.objects(Signature.self))

            signaturesToAdd = updatedSignatures.filter { updatedElement in
                !existingSignatures.contains(updatedElement)
            }

            signaturesToUpdate = updatedSignatures.filter { updatedElement in
                existingSignatures.contains(updatedElement)
            }

            signaturesToDelete = existingSignatures.filter { existingElement in
                !updatedSignatures.contains(existingElement)
            }

            // NOTE: local drafts in `signaturesToDelete` should be migrated to use the new default signature.

            // Update signatures in Realm
            try? realm.safeWrite {
                realm.add(signaturesToUpdate, update: .modified)
                realm.delete(signaturesToDelete)
                realm.add(signaturesToAdd, update: .modified)
            }
        }
    }

    func updateSignature(signature: Signature) async throws {
        try await apiFetcher.updateSignature(mailbox: mailbox, signature: signature)
        try await refreshAllSignatures()
    }

    func getStoredSignatures(using realm: Realm? = nil) -> [Signature] {
        let realm = realm ?? getRealm()
        return Array(realm.objects(Signature.self))
    }
}
