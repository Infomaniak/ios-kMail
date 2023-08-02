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
import InfomaniakCoreUI
import InfomaniakDI
import MailResources
import RealmSwift
import Sentry
import SwiftSoup
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
                identifierQueue[uuid] = .invalid
            }
        }
    }
}

public final class DraftManager {
    private let draftQueue = DraftQueue()
    private static let saveExpirationSec = 3

    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var messagePresentable: MessagePresentable

    /// Used by DI only
    public init() {
        // META: Silencing Sonarcloud
    }

    /// Save a draft server side
    private func saveDraftRemotely(draft: Draft, mailboxManager: MailboxManager) async {
        guard draft.identityId != nil else {
            SentrySDK.capture(message: "We are trying to send a draft without an identityId, this will fail.")
            return
        }

        matomo.track(eventWithCategory: .newMessage, name: "saveDraft")

        await draftQueue.cleanQueueElement(uuid: draft.localUUID)
        await draftQueue.beginBackgroundTask(withName: "Draft Saver", for: draft.localUUID)

        do {
            try await mailboxManager.save(draft: draft)
        } catch {
            guard error.shouldDisplay else { return }
            messagePresentable.show(message: error.localizedDescription)
        }
        await draftQueue.endBackgroundTask(uuid: draft.localUUID)
    }

    public func send(draft: Draft, mailboxManager: MailboxManager) async -> Date? {
        messagePresentable.show(message: MailResourcesStrings.Localizable.snackbarEmailSending)

        var sendDate: Date?
        await draftQueue.cleanQueueElement(uuid: draft.localUUID)
        await draftQueue.beginBackgroundTask(withName: "Draft Sender", for: draft.localUUID)

        do {
            let cancelableResponse = try await mailboxManager.send(draft: draft)
            messagePresentable.show(message: MailResourcesStrings.Localizable.snackbarEmailSent)
            sendDate = cancelableResponse.scheduledDate
        } catch {
            messagePresentable.show(message: error.localizedDescription)
        }
        await draftQueue.endBackgroundTask(uuid: draft.localUUID)
        return sendDate
    }

    public func syncDraft(mailboxManager: MailboxManager) {
        let drafts = mailboxManager.draftWithPendingAction().freezeIfNeeded()
        Task {
            let latestSendDate = await withTaskGroup(of: Date?.self, returning: Date?.self) { group in
                for draft in drafts {
                    group.addTask {
                        var sendDate: Date?
                        switch draft.action {
                        case .initialSave:
                            await self.initialSaveRemotelyAndNotify(draft: draft, mailboxManager: mailboxManager)
                        case .save:
                            await self.saveDraftRemotely(draft: draft, mailboxManager: mailboxManager)
                        case .send:
                            sendDate = await self.send(draft: draft, mailboxManager: mailboxManager)
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

    /// Process a `draft` when the ShareExtension dismisses.
    /// - Parameters:
    ///   - draft: Expecting a .detached draft
    ///   - mailboxManager: the mailbox manager
    public func saveAndProcessDraftFromShareExtension(draft: Draft, mailboxManager: MailboxManager) {
        Task {
            let saved = await self.initialSaveRemotelyIfNonEmpty(draft: draft, mailboxManager: mailboxManager)

            // No message for empty draft
            guard saved else {
                return
            }

            // Present a matching message
            @InjectService var messagePresentable: MessagePresentable
            if draft.action == .send {
                messagePresentable.show(message: MailResourcesStrings.Localizable.snackbarEmailSending)
            } else {
                messagePresentable.show(message: MailResourcesStrings.Localizable.snackbarDraftSaved)
            }
        }
    }

    /// First save of a draft with the remote if non empty
    @discardableResult
    private func initialSaveRemotelyIfNonEmpty(draft: Draft, mailboxManager: MailboxManager) async -> Bool {
        guard !isDraftEmpty(draft: draft) else {
            deleteEmptyDraft(draft: draft, for: mailboxManager)
            return false
        }

        await saveDraftRemotely(draft: draft, mailboxManager: mailboxManager)
        return true
    }

    /// First save of a draft with the remote if non empty.
    ///
    /// Present a message with a `delete draft`  action
    @discardableResult
    public func initialSaveRemotelyAndNotify(draft: Draft, mailboxManager: MailboxManager) async -> Bool {
        let saved = await initialSaveRemotelyIfNonEmpty(draft: draft, mailboxManager: mailboxManager)
        if saved {
            let messageAction: MessageAction = (MailResourcesStrings.Localizable.actionDelete, { [weak self] in
                self?.matomo.track(eventWithCategory: .snackbar, name: "deleteDraft")
                self?.deleteDraftSnackBarAction(draft: draft, mailboxManager: mailboxManager)
            })
            messagePresentable.show(message: MailResourcesStrings.Localizable.snackbarDraftSaved, action: messageAction)
        }
        return saved
    }

    /// Check multiple conditions to infer if a draft is empty or not
    private func isDraftEmpty(draft: Draft) -> Bool {
        guard isDraftBodyEmptyOfAttachments(draft: draft) else {
            return false
        }

        guard (try? isDraftBodyEmptyOfChanges(draft.body)) ?? true else {
            return false
        }

        return true
    }

    /// Check that the draft has some Attachments of not
    private func isDraftBodyEmptyOfAttachments(draft: Draft) -> Bool {
        // This excludes the signature attachments that are present in Draft.attachments
        return draft.attachments.filter { $0.contentId == nil }.isEmpty
    }

    /// Check if once the Signature node is removed, we still have content
    internal func isDraftBodyEmptyOfChanges(_ body: String) throws -> Bool {
        guard !body.isEmpty else {
            return true
        }

        // Load DOM structure
        let document = try SwiftSoup.parse(body)

        // Remove the signature node
        guard let signatureNode = try document.getElementsByClass(Constants.signatureWrapperIdentifier).first() else {
            return !document.hasText()
        }
        try signatureNode.remove()

        // Do we still have text ?
        return !document.hasText()
    }

    private func refreshDraftFolder(latestSendDate: Date?, mailboxManager: MailboxManager) async throws {
        if let draftFolder = mailboxManager.getFolder(with: .draft)?.freeze() {
            await mailboxManager.refresh(folder: draftFolder)

            if let latestSendDate {
                /*
                    We need to refresh the draft folder after the mail is sent to make it disappear, we wait at least 1.5 seconds
                    because the sending process is not synchronous
                 */
                let delay = latestSendDate.timeIntervalSinceNow
                try await Task.sleep(nanoseconds: UInt64(1_000_000_000 * max(Double(delay), 1.5)))
                await mailboxManager.refresh(folder: draftFolder)
            }

            await mailboxManager.deleteOrphanDrafts()
        }
    }

    private func deleteDraftSnackBarAction(draft: Draft, mailboxManager: MailboxManager) {
        Task {
            await tryOrDisplayError {
                if let liveDraft = draft.thaw() {
                    try await mailboxManager.delete(draft: liveDraft.freeze())
                    messagePresentable.show(message: MailResourcesStrings.Localizable.snackbarDraftDeleted)
                    if let draftFolder = mailboxManager.getFolder(with: .draft)?.freeze() {
                        await mailboxManager.refresh(folder: draftFolder)
                    }
                }
            }
        }
    }

    private func deleteEmptyDraft(draft: Draft, for mailboxManager: MailboxManager) {
        let primaryKey = draft.localUUID
        let realm = mailboxManager.getRealm()
        try? realm.write {
            guard let object = realm.object(ofType: Draft.self, forPrimaryKey: primaryKey) else {
                return
            }
            realm.delete(object)
        }
    }

    private func defaultSignature(for mailboxManager: MailboxManager) -> Signature? {
        guard let signature = mailboxManager.getStoredSignatures().defaultSignature else {
            return nil
        }

        return signature
    }
}
