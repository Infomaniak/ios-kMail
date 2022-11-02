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
import InfomaniakCore
import MailResources

public class DraftManager {
    public static let shared = DraftManager()

    private var draftSaveTasksQueued = [String: Task<Void, Never>]()
    private static let saveExpirationNanoSec: UInt64 = 3_000_000_000 // 3 sec

    private init() {}

    public func saveDraftOnline(draft: UnmanagedDraft, mailboxManager: MailboxManager) async {
        cancelAndRemoveTask(draftUUID: draft.localUUID)
        await saveDraft(draft: draft, mailboxManager: mailboxManager, showSnackBar: true)
    }

    public func saveDraftLocally(draft: UnmanagedDraft, mailboxManager: MailboxManager) {
        cancelAndRemoveTask(draftUUID: draft.localUUID)
        draftSaveTasksQueued[draft.localUUID] = Task {
            // Debounce the save task
            try? await Task.sleep(nanoseconds: DraftManager.saveExpirationNanoSec)

            await mailboxManager.saveLocally(draft: draft)
        }
    }

    private func saveDraft(draft: UnmanagedDraft,
                           mailboxManager: MailboxManager,
                           showSnackBar: Bool = false) async {
        let error = await mailboxManager.save(draft: draft)
        if let error = error, error.shouldDisplay {
            await IKSnackBar.showSnackBar(message: error.localizedDescription)
        } else if showSnackBar {
            await IKSnackBar.showSnackBar(message: MailResourcesStrings.Localizable.snackBarDraftSaved,
                                          action: .init(title: MailResourcesStrings.Localizable.actionDelete) { [weak self] in
                                              self?.deleteDraft(localUuid: draft.localUUID, mailboxManager: mailboxManager)
                                          })
        }
    }

    private func deleteDraft(localUuid: String, mailboxManager: MailboxManager) {
        // Convert draft to thread
        let realm = mailboxManager.getRealm()

        guard let draft = mailboxManager.draft(localUuid: localUuid, using: realm)?.freeze(),
              let draftFolder = mailboxManager.getFolder(with: .draft, using: realm) else { return }
        let thread = Thread(draft: draft)
        try? realm.uncheckedSafeWrite {
            realm.add(thread, update: .modified)
            draftFolder.threads.insert(thread)
        }
        let frozenThread = thread.freeze()
        // Delete
        Task {
            await tryOrDisplayError {
                _ = try await mailboxManager.move(thread: frozenThread, to: .trash)
                await IKSnackBar.showSnackBar(message: MailResourcesStrings.Localizable.snackBarDraftDeleted)
            }
        }
    }

    public func send(draft: UnmanagedDraft, mailboxManager: MailboxManager) async {
        // Cancel any scheduled save
        cancelAndRemoveTask(draftUUID: draft.localUUID)
        do {
            let cancelableResponse = try await mailboxManager.send(draft: draft)
            await IKSnackBar.showCancelableSnackBar(
                message: MailResourcesStrings.Localizable.emailSentSnackbar,
                cancelSuccessMessage: MailResourcesStrings.Localizable.canceledEmailSendingConfirmationSnackbar,
                duration: .custom(CGFloat(draft.delay ?? 3)),
                undoRedoAction: UndoRedoAction(undo: cancelableResponse, redo: nil),
                mailboxManager: mailboxManager
            )
        } catch {
            await IKSnackBar.showSnackBar(message: error.localizedDescription)
        }
    }

    private func cancelAndRemoveTask(draftUUID: String) {
        draftSaveTasksQueued[draftUUID]?.cancel()
        draftSaveTasksQueued[draftUUID] = nil
    }
}
