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

// MARK: - Signatures

public extension MailboxManager {
    func refreshAllSignatures() async throws {
        try await refreshActor.refreshAllSignatures()
    }

    func updateSignature(signature: Signature?) async throws {
        try await apiFetcher.updateSignature(mailbox: mailbox, signature: signature)
        try await refreshAllSignatures()
    }

    func getStoredSignatures() -> [Signature] {
        let signatures = fetchResults(ofType: Signature.self) { partial in
            partial
        }

        return Array(signatures)
    }

    func getStoredSignatures(using realm: Realm) -> [Signature] {
        return Array(realm.objects(Signature.self))
    }
}
