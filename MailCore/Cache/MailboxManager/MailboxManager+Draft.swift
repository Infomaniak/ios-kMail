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

// MARK: - Draft

public extension MailboxManager {
    func draftWithPendingAction() -> Results<Draft> {
        fetchResults(ofType: Draft.self) { partial in
            partial.where { $0.action != nil }
        }
    }

    func draft(messageUid: String) -> Draft? {
        fetchObject(ofType: Draft.self) { partial in
            partial.where { $0.messageUid == messageUid }.first
        }
    }

    func draft(messageUid: String, using realm: Realm) -> Draft? {
        return realm.objects(Draft.self).where { $0.messageUid == messageUid }.first
    }

    func draft(localUuid: String) -> Draft? {
        fetchObject(ofType: Draft.self, forPrimaryKey: localUuid)
    }

    func draft(localUuid: String, using realm: Realm) -> Draft? {
        return realm.object(ofType: Draft.self, forPrimaryKey: localUuid)
    }

    func draft(remoteUuid: String) -> Draft? {
        fetchObject(ofType: Draft.self) { partial in
            partial.where { $0.remoteUUID == remoteUuid }.first
        }
    }

    func draft(remoteUuid: String, using realm: Realm) -> Draft? {
        return realm.objects(Draft.self).where { $0.remoteUUID == remoteUuid }.first
    }

    func send(draft: Draft) async throws -> SendResponse {
        do {
            let cancelableResponse = try await apiFetcher.send(mailbox: mailbox, draft: draft)
            // Once the draft has been sent, we can delete it from Realm
            try await deleteLocally(draft: draft)
            return cancelableResponse
        } catch let error as AFErrorWithContext where (200 ... 299).contains(error.request.response?.statusCode ?? 0) {
            // Status code is valid but something went wrong eg. we couldn't parse the response
            try await deleteLocally(draft: draft)
            throw error
        } catch let error as MailApiError {
            // Do not delete draft on invalid identity
            guard error != MailApiError.apiIdentityNotFound else {
                throw error
            }

            // The api returned an error
            try await deleteLocally(draft: draft)
            throw error
        }
    }

    func save(draft: Draft) async throws {
        do {
            let saveResponse = try await apiFetcher.save(mailbox: mailbox, draft: draft)
            try? writeTransaction { writableRealm in
                // Update draft in Realm
                guard let liveDraft = writableRealm.object(ofType: Draft.self, forPrimaryKey: draft.localUUID) else {
                    self.logError(.missingDraft)
                    return
                }

                liveDraft.remoteUUID = saveResponse.uuid
                liveDraft.messageUid = saveResponse.uid
                liveDraft.action = nil
            }
        } catch let error as MailApiError {
            // Do not delete draft on invalid identity
            guard error != MailApiError.apiIdentityNotFound else {
                throw error
            }

            // The api returned an error for now we can do nothing about it so we delete the draft
            try await deleteLocally(draft: draft)
            throw error
        }
    }

    func delete(draft: Draft) async throws {
        try await deleteLocally(draft: draft)
        try await apiFetcher.deleteDraft(mailbox: mailbox, draftId: draft.remoteUUID)
    }

    func delete(draftMessage: Message) async throws {
        guard let draftResource = draftMessage.draftResource else {
            throw MailError.resourceError
        }

        let draft = fetchObject(ofType: Draft.self) { partial in
            partial
                .where { $0.remoteUUID == draftResource }
                .first?
                .freeze()
        }

        if let draft {
            try await deleteLocally(draft: draft)
        }

        try await apiFetcher.deleteDraft(draftResource: draftResource)
        try await refreshFolder(from: [draftMessage], additionalFolder: nil)
    }

    func deleteLocally(draft: Draft) async throws {
        try? writeTransaction { writableRealm in
            guard let liveDraft = writableRealm.object(ofType: Draft.self, forPrimaryKey: draft.localUUID) else {
                self.logError(.missingDraft)
                return
            }

            writableRealm.delete(liveDraft)
        }
    }

    func deleteOrphanDrafts() async {
        guard let draftFolder = getFolder(with: .draft) else {
            logError(.missingFolder)
            return
        }

        let existingMessageUids = Set(draftFolder.threads.flatMap(\.messages).map(\.uid))

        try? writeTransaction { writableRealm in
            let noActionDrafts = writableRealm.objects(Draft.self).where { $0.action == nil }
            for draft in noActionDrafts {
                if let messageUid = draft.messageUid,
                   !existingMessageUids.contains(messageUid) {
                    writableRealm.delete(draft)
                }
            }
        }
    }
}
