/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

import Collections
import Foundation
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakDI

class CancelableTaskExpiringActivity: ExpiringActivityDelegate {
    let cancelClosure: () -> Void

    init(cancelClosure: @escaping () -> Void) {
        self.cancelClosure = cancelClosure
    }

    func backgroundActivityExpiring() {
        cancelClosure()
    }
}

private struct RefreshTask {
    let mailboxId: String
    let folder: Folder
    let task: Task<Void, Never>

    func fuzzyEquals(mailboxId: String, folder: Folder) -> Bool {
        guard let currentRole = self.folder.role,
              let newRole = folder.role,
              self.mailboxId == mailboxId
        else {
            return self.folder.remoteId == folder.remoteId && self.mailboxId == mailboxId
        }

        if MailboxManager.additionalFolderRolesToFetch.contains(currentRole)
            && MailboxManager.additionalFolderRolesToFetch.contains(newRole) {
            return true
        }

        return self.folder.remoteId == folder.remoteId
    }
}

public actor RefreshActor {
    weak var mailboxManager: MailboxManager?

    private var refreshTask: RefreshTask?

    public init(mailboxManager: MailboxManager) {
        self.mailboxManager = mailboxManager
    }

    public func flushFolder(folder: Folder, mailbox: Mailbox, apiFetcher: any MailApiFetchable) async throws -> Bool {
        let response = try await apiFetcher.flushFolder(mailbox: mailbox, folderId: folder.remoteId)
        await refreshFolderContent(folder)
        return response
    }

    public func refreshFolders(folders: OrderedSet<Folder>) async throws {
        let updateFolders = Task {
            for folder in folders {
                guard !Task.isCancelled else { break }
                await refreshFolderContent(folder)
            }
        }

        let cancelableTaskExpiringActivity = CancelableTaskExpiringActivity {
            updateFolders.cancel()

            Task {
                await self.cancelRefresh()
            }
        }
        // Track progress in background with a cancelation handler
        let expiringActivity = ExpiringActivity(id: #function + UUID().uuidString, delegate: cancelableTaskExpiringActivity)
        expiringActivity.start()

        await updateFolders.finish()

        expiringActivity.endAll()
    }

    public func refreshFolder(from messages: [Message], additionalFolder: Folder?) async throws {
        var folders = messages.compactMap(\.folder)
        if let additionalFolder {
            folders.append(additionalFolder)
        }

        try await refreshFolders(folders: OrderedSet(folders))
    }

    public func refreshFolderContent(_ folder: Folder) async {
        guard let mailboxManager else { return }

        let mailboxId = mailboxManager.mailboxObjectId
        while let refreshTask {
            if !refreshTask.task.isCancelled, refreshTask.fuzzyEquals(mailboxId: mailboxId, folder: folder) {
                _ = await refreshTask.task.result
                return
            }

            refreshTask.task.cancel()
            _ = await refreshTask.task.result
            self.refreshTask = nil
        }

        let task = Task {
            await tryOrDisplayError {
                do {
                    try await mailboxManager.threads(folder: folder)
                } catch let error as AFErrorWithContext where error.afError.responseCode ?? 0 >= 500 {
                    throw error
                }
            }
        }
        let refreshTask = RefreshTask(mailboxId: mailboxId, folder: folder, task: task)
        self.refreshTask = refreshTask

        _ = await task.result
        self.refreshTask = nil
    }

    public func cancelRefresh() async {
        refreshTask?.task.cancel()
        _ = await refreshTask?.task.result
        refreshTask = nil
    }

    // MARK: Signatures

    /// Refresh all signatures.
    public func refreshAllSignatures() async throws {
        guard let mailboxManager else {
            return
        }

        // Get from API
        let signaturesResult = try await mailboxManager.apiFetcher.signatures(mailbox: mailboxManager.mailbox)
        var updatedSignatures = Set(signaturesResult.signatures)

        if let defaultReplyId = signaturesResult.defaultReplySignatureId {
            updatedSignatures.first {
                $0.id == defaultReplyId
            }?.isDefaultReply = true
        }

        try? mailboxManager.writeTransaction { writableRealm in
            let signaturesToDelete: Set<Signature> // no longer present server side
            let signaturesToUpdate: [Signature] // updated signatures
            let signaturesToAdd: [Signature] // new signatures

            // fetch all local signatures
            let existingSignatures = Array(writableRealm.objects(Signature.self))

            // filter out signatures that may no longer be valid realm objects
            updatedSignatures = updatedSignatures.filter { !$0.isInvalidated }

            signaturesToAdd = updatedSignatures.filter { updatedElement in
                !existingSignatures.contains(updatedElement)
            }

            signaturesToUpdate = updatedSignatures.filter { updatedElement in
                existingSignatures.contains(updatedElement)
            }

            signaturesToDelete = Set(existingSignatures.filter { existingElement in
                !updatedSignatures.contains(existingElement)
            })

            // NOTE: local drafts in `signaturesToDelete` should be migrated to use the new default signature.

            // Update signatures in Realm
            writableRealm.add(signaturesToUpdate, update: .modified)
            writableRealm.delete(signaturesToDelete)
            writableRealm.add(signaturesToAdd, update: .modified)
        }
    }
}
