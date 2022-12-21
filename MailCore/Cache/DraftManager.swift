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
import UIKit

struct DraftQueueElement {
    var saveTask: Task<Void, Never>?
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
}

actor DraftQueue {
    private var taskQueue = [String: DispatchWorkItem]()
    private var identifierQueue = [String: UIBackgroundTaskIdentifier]()

    func cleanQueueElement(uuid: String) {
        taskQueue[uuid]?.cancel()
        endBackgroundTask(uuid: uuid)
        taskQueue[uuid] = nil
        identifierQueue[uuid] = .invalid
    }

    func saveTask(task: DispatchWorkItem, for uuid: String) {
        taskQueue[uuid] = task
    }

    func beginBackgroundTask(withName name: String, for uuid: String) async {
        let identifier = await UIApplication.shared.beginBackgroundTask(withName: name) { [self] in
            Task {
                endBackgroundTask(uuid: uuid)
            }
        }
        identifierQueue[uuid] = identifier
    }

    func endBackgroundTask(uuid: String) {
        if let identifier = identifierQueue[uuid], identifier != .invalid {
            Task {
                await UIApplication.shared.endBackgroundTask(identifier)
            }
        }
    }
}

public class DraftManager {
    public static let shared = DraftManager()

    private let draftQueue = DraftQueue()
    private static let saveExpirationSec = 3

    private init() {}

    private func saveDraft(draft: Draft, mailboxManager: MailboxManager) async {
        await draftQueue.cleanQueueElement(uuid: draft.localUUID)
        await draftQueue.beginBackgroundTask(withName: "Draft Saver", for: draft.localUUID)

        do {
            try await mailboxManager.save(draft: draft)
        } catch {
            if error.shouldDisplay {
                await IKSnackBar.showSnackBar(message: error.localizedDescription)
            }
        }
        await draftQueue.endBackgroundTask(uuid: draft.localUUID)
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
                _ = try await mailboxManager.move(threads: [frozenThread], to: .trash)
                await IKSnackBar.showSnackBar(message: MailResourcesStrings.Localizable.snackBarDraftDeleted)
            }
        }
    }

    public func send(draft: Draft, mailboxManager: MailboxManager) async {
        await draftQueue.cleanQueueElement(uuid: draft.localUUID)
        await draftQueue.beginBackgroundTask(withName: "Draft Sender", for: draft.localUUID)

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
        await draftQueue.endBackgroundTask(uuid: draft.localUUID)
    }

    public func syncDraft(mailboxManager: MailboxManager) {
        let drafts = mailboxManager.draftWithPendingAction().freezeIfNeeded()
        let emptyDraftBody = emptyDraftBodyWithSignature(for: mailboxManager)
        Task {
            await withTaskGroup(of: Void.self) { group in
                for draft in drafts {
                    group.addTask {
                        switch draft.action {
                        case .initialSave:
                            guard draft.body != emptyDraftBody else {
                                self.deleteEmptyDraft(draft: draft)
                                return
                            }

                            await self.saveDraft(draft: draft, mailboxManager: mailboxManager)
                            await IKSnackBar.showSnackBar(message: MailResourcesStrings.Localizable.snackBarDraftSaved,
                                                          action: .init(title: MailResourcesStrings.Localizable.actionDelete) { [weak self] in
                                                              self?.deleteDraft(localUuid: draft.localUUID, mailboxManager: mailboxManager)
                                                          })
                        case .save:
                            await self.saveDraft(draft: draft, mailboxManager: mailboxManager)
                        case .send:
                            await self.send(draft: draft, mailboxManager: mailboxManager)
                        default:
                            break
                        }
                    }
                }
            }
        }
    }

    private func deleteEmptyDraft(draft: Draft) {
        guard let liveDraft = draft.thaw(),
              let realm = liveDraft.realm else { return }
        try? realm.write {
            realm.delete(liveDraft)
        }
    }

    private func emptyDraftBodyWithSignature(for mailboxManager: MailboxManager) -> String {
        let draft = Draft()
        if let signature = mailboxManager.getSignatureResponse() {
            draft.setSignature(signature)
        }
        return draft.body
    }
}
