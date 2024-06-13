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

import Foundation
import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailResources
import RealmSwift
import Sentry
import SwiftSoup
import UIKit

actor DraftQueue {
    private var taskQueue = [String: DispatchWorkItem]()
    private var identifierQueue = [String: UIBackgroundTaskIdentifier]()

    func cleanQueueElement(uuid: String) {
        taskQueue[uuid]?.cancel()
        endBackgroundTask(uuid: uuid)
        taskQueue[uuid] = nil
        identifierQueue[uuid] = .invalid
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
                identifierQueue[uuid] = .invalid
            }
        }
    }
}

public final class DraftManager {
    private let draftQueue = DraftQueue()

    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var alertDisplayable: UserAlertDisplayable

    /// Used by DI only
    public init() {}

    /// Save a draft server side
    private func saveDraftRemotely(
        draft initialDraft: Draft,
        mailboxManager: MailboxManager,
        retry: Bool = true,
        showSnackbar: Bool
    ) async {
        guard initialDraft.identityId != nil else {
            SentrySDK.capture(message: "We are trying to send a draft without an identityId, this will fail.")
            return
        }

        matomo.track(eventWithCategory: .newMessage, name: "saveDraft")

        await draftQueue.cleanQueueElement(uuid: initialDraft.localUUID)
        await draftQueue.beginBackgroundTask(withName: "Draft Saver", for: initialDraft.localUUID)

        let draft = updateSubjectIfNeeded(draft: initialDraft)

        do {
            try await mailboxManager.save(draft: draft)
        } catch {
            // Refresh signatures and retry with default signature on missing identity
            if retry,
               let mailError = error as? MailApiError,
               mailError == MailApiError.apiIdentityNotFound {
                try? await mailboxManager.refreshAllSignatures()
                guard let updatedDraft = await setDefaultSignature(draft: draft, mailboxManager: mailboxManager) else {
                    return
                }
                await saveDraftRemotely(
                    draft: updatedDraft,
                    mailboxManager: mailboxManager,
                    retry: false,
                    showSnackbar: showSnackbar
                )
            }
            // show error if needed
            else {
                guard error.shouldDisplay else { return }
                if showSnackbar {
                    alertDisplayable.show(message: error.localizedDescription)
                }
            }
        }
        await draftQueue.endBackgroundTask(uuid: draft.localUUID)
    }

    /// Set a default signature to a draft, from existing ones in DB
    private func setDefaultSignature(draft: Draft, mailboxManager: MailboxManager) async -> Draft? {
        let storedSignatures = mailboxManager.getStoredSignatures()
        guard let defaultSignature = storedSignatures.defaultSignature else {
            return nil
        }

        var updatedDraft: Draft?
        try? mailboxManager.writeTransaction { writableRealm in
            guard let liveDraft = writableRealm.object(ofType: Draft.self, forPrimaryKey: draft.localUUID) else {
                return
            }

            liveDraft.identityId = "\(defaultSignature.id)"
            writableRealm.add(liveDraft, update: .modified)
            updatedDraft = liveDraft.detached()
        }

        return updatedDraft
    }

    public func send(draft initialDraft: Draft, mailboxManager: MailboxManager, retry: Bool = true,
                     showSnackbar: Bool) async -> Date? {
        if showSnackbar {
            alertDisplayable.show(message: MailResourcesStrings.Localizable.snackbarEmailSending)
        }

        var sendDate: Date?
        await draftQueue.cleanQueueElement(uuid: initialDraft.localUUID)
        await draftQueue.beginBackgroundTask(withName: "Draft Sender", for: initialDraft.localUUID)

        let draft = updateSubjectIfNeeded(draft: initialDraft)

        do {
            let cancelableResponse = try await mailboxManager.send(draft: draft)
            if showSnackbar {
                alertDisplayable.show(message: MailResourcesStrings.Localizable.snackbarEmailSent)
            }
            sendDate = cancelableResponse.scheduledDate
        } catch {
            // Refresh signatures and retry with default signature on missing identity
            if retry,
               let mailError = error as? MailApiError,
               mailError == MailApiError.apiIdentityNotFound {
                try? await mailboxManager.refreshAllSignatures()
                guard let updatedDraft = await setDefaultSignature(draft: draft, mailboxManager: mailboxManager) else {
                    return nil
                }
                return await send(draft: updatedDraft, mailboxManager: mailboxManager, retry: false, showSnackbar: showSnackbar)
            }

            if showSnackbar {
                alertDisplayable.show(message: error.localizedDescription)
            }
        }
        await draftQueue.endBackgroundTask(uuid: draft.localUUID)
        return sendDate
    }

    public func syncDraft(mailboxManager: MailboxManager, showSnackbar: Bool) {
        let drafts = mailboxManager.draftWithPendingAction().freezeIfNeeded()
        Task {
            let latestSendDate = await withTaskGroup(of: Date?.self, returning: Date?.self) { group in
                for draft in drafts {
                    group.addTask {
                        var sendDate: Date?
                        switch draft.action {
                        case .initialSave:
                            await self.initialSaveRemotely(
                                draft: draft,
                                mailboxManager: mailboxManager,
                                showSnackbar: showSnackbar
                            )
                        case .save:
                            await self.saveDraftRemotely(draft: draft, mailboxManager: mailboxManager, showSnackbar: showSnackbar)
                        case .send:
                            sendDate = await self.send(draft: draft, mailboxManager: mailboxManager, showSnackbar: showSnackbar)
                        default:
                            break
                        }
                        return sendDate
                    }
                }

                var latestSendDate: Date?
                for await result in group {
                    latestSendDate = result
                }
                return latestSendDate
            }

            try await refreshDraftFolder(latestSendDate: latestSendDate, mailboxManager: mailboxManager)
        }
    }

    /// First save of a draft with the remote, if non empty.
    ///
    /// Present a message with a `delete draft`  action
    @discardableResult
    public func initialSaveRemotely(draft: Draft, mailboxManager: MailboxManager, showSnackbar: Bool) async -> Bool {
        guard !draft.shouldBeSaved else {
            deleteEmptyDraft(draft: draft, for: mailboxManager)
            return false
        }

        await saveDraftRemotely(draft: draft, mailboxManager: mailboxManager, showSnackbar: showSnackbar)

        let messageAction: UserAlertAction = (MailResourcesStrings.Localizable.actionDelete, { [weak self] in
            self?.matomo.track(eventWithCategory: .snackbar, name: "deleteDraft")
            self?.deleteDraftSnackBarAction(draft: draft, mailboxManager: mailboxManager)
        })
        if showSnackbar {
            alertDisplayable.show(message: MailResourcesStrings.Localizable.snackbarDraftSaved, action: messageAction)
        }

        return true
    }

    private func refreshDraftFolder(latestSendDate: Date?, mailboxManager: MailboxManager) async throws {
        if let draftFolder = mailboxManager.getFolder(with: .draft)?.freeze() {
            await mailboxManager.refreshFolderContent(draftFolder)

            if let latestSendDate {
                /*
                    We need to refresh the draft folder after the mail is sent to make it disappear, we wait at least 1.5 seconds
                    because the sending process is not synchronous
                 */
                let delay = latestSendDate.timeIntervalSinceNow
                try await Task.sleep(nanoseconds: UInt64(1_000_000_000 * max(Double(delay), 1.5)))
                await mailboxManager.refreshFolderContent(draftFolder)
            }

            await mailboxManager.deleteOrphanDrafts()
        }
    }

    private func deleteDraftSnackBarAction(draft: Draft, mailboxManager: MailboxManager) {
        Task {
            await tryOrDisplayError {
                if let liveDraft = draft.thaw() {
                    try await mailboxManager.delete(draft: liveDraft.freeze())
                    alertDisplayable.show(message: MailResourcesStrings.Localizable.snackbarDraftDeleted)
                    if let draftFolder = mailboxManager.getFolder(with: .draft)?.freeze() {
                        await mailboxManager.refreshFolderContent(draftFolder)
                    }
                }
            }
        }
    }

    private func deleteEmptyDraft(draft: Draft, for mailboxManager: MailboxManager) {
        let primaryKey = draft.localUUID
        try? mailboxManager.writeTransaction { writableRealm in
            guard let object = writableRealm.object(ofType: Draft.self, forPrimaryKey: primaryKey) else {
                return
            }
            writableRealm.delete(object)
        }
    }

    private func updateSubjectIfNeeded(draft: Draft) -> Draft {
        guard draft.subject.count > 998, let liveDraft = draft.thaw() else {
            return draft
        }

        let subject = draft.subject
        let index = subject.index(subject.startIndex, offsetBy: 998)

        try? liveDraft.realm?.write {
            liveDraft.subject = String(subject[..<index])
        }
        return liveDraft.freeze()
    }
}
