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
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailResources
import RealmSwift
import Sentry
import SwiftSoup
import UIKit

public final class DraftManager {
    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var alertDisplayable: UserAlertDisplayable

    private var currentSyncTask: Task<Void, Never>?

    /// Used by DI only
    public init() {}

    public enum ErrorDomain: Error {
        case draftNotFound
        case invalidDraftAction
        case sendQuota
        case cannotSendDraft
        case missingIdentity
    }

    private func syncDraftJob(
        mailboxManager: MailboxManager,
        showSnackbar: Bool,
        changeFolderAction: ((Folder) -> Void)? = nil,
        kSuiteUpgradeAction: ((LocalPack) -> Void)? = nil
    ) async {
        let drafts = mailboxManager.draftWithPendingAction().freezeIfNeeded()

        var backgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
        backgroundTaskIdentifier = await UIApplication.shared.beginBackgroundTask(withName: "Draft Sync") {
            guard backgroundTaskIdentifier != .invalid else { return }
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
        }

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
                    case .send, .sendReaction, .schedule:
                        sendDate = try? await self.sendOrSchedule(
                            draft: draft,
                            mailboxManager: mailboxManager,
                            showSnackbar: showSnackbar,
                            changeFolderAction: changeFolderAction,
                            kSuiteUpgradeAction: kSuiteUpgradeAction
                        )
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

        if backgroundTaskIdentifier != .invalid {
            await UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
        }

        try? await refreshDraftFolder(latestSendDate: latestSendDate, mailboxManager: mailboxManager)
    }

    public func syncDraft(
        mailboxManager: MailboxManager,
        showSnackbar: Bool,
        changeFolderAction: ((Folder) -> Void)? = nil,
        kSuiteUpgradeAction: ((LocalPack) -> Void)? = nil
    ) async {
        if currentSyncTask != nil {
            await currentSyncTask?.value
        }
        currentSyncTask = Task {
            await syncDraftJob(
                mailboxManager: mailboxManager,
                showSnackbar: showSnackbar,
                changeFolderAction: changeFolderAction,
                kSuiteUpgradeAction: kSuiteUpgradeAction
            )
        }

        await currentSyncTask?.value
        currentSyncTask = nil
    }

    public func startSyncDraft(
        mailboxManager: MailboxManager,
        showSnackbar: Bool,
        changeFolderAction: ((Folder) -> Void)? = nil,
        kSuiteUpgradeAction: ((LocalPack) -> Void)? = nil
    ) {
        Task {
            await syncDraft(
                mailboxManager: mailboxManager,
                showSnackbar: showSnackbar,
                changeFolderAction: changeFolderAction,
                kSuiteUpgradeAction: kSuiteUpgradeAction
            )
        }
    }

    public func sendDraft(localUUID: String, mailboxManager: MailboxManager) async throws {
        guard let liveDraft = mailboxManager.fetchObject(ofType: Draft.self, forPrimaryKey: localUUID) else {
            throw ErrorDomain.draftNotFound
        }

        guard liveDraft.action == .send || liveDraft.action == .sendReaction else {
            throw ErrorDomain.invalidDraftAction
        }

        let sendDate = try await sendOrSchedule(
            draft: liveDraft.freezeIfNeeded(),
            mailboxManager: mailboxManager,
            showSnackbar: true
        )

        Task {
            try? await refreshDraftFolder(latestSendDate: sendDate, mailboxManager: mailboxManager)
        }
    }

    /// Save a draft server side
    private func saveDraftRemotely(
        draft initialDraft: Draft,
        mailboxManager: MailboxManager,
        retry: Bool = true,
        showSnackbar: Bool
    ) async {
        matomo.track(eventWithCategory: .newMessage, name: "saveDraft")

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
            } else {
                guard error.shouldDisplay else { return }
                alertDisplayable.show(message: error.localizedDescription, shouldShow: showSnackbar)
            }
        }
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

    private func sendOrSchedule(
        draft initialDraft: Draft,
        mailboxManager: MailboxManager,
        retry: Bool = true,
        showSnackbar: Bool,
        changeFolderAction: ((Folder) -> Void)? = nil,
        kSuiteUpgradeAction: ((LocalPack) -> Void)? = nil,
    ) async throws -> Date? {
        showWillSendSnackbar(action: initialDraft.action, showSnackbar: showSnackbar)

        let draft = updateSubjectIfNeeded(draft: initialDraft)

        do {
            if draft.action == .send || draft.action == .sendReaction {
                let sendResponse = try await mailboxManager.send(draft: draft)
                let sendDate = sendResponse.scheduledDate

                var action: UserAlertAction?
                if let cancelResource = sendResponse.cancelResource {
                    action = UserAlertAction(MailResourcesStrings.Localizable.buttonCancel) {
                        Task {
                            try await mailboxManager.apiFetcher.cancelSend(resource: cancelResource)

                            self.removeReactionIfNeeded(mailboxManager: mailboxManager, draft: draft)
                        }
                    }
                }

                showDidSendSnackbar(
                    draft: draft,
                    mailboxManager: mailboxManager,
                    showSnackbar: showSnackbar,
                    action: action
                )

                return sendDate
            } else if draft.action == .schedule {
                let draftWithoutDelay = removeDelay(draft: draft)
                let scheduleResponse = try await mailboxManager.schedule(draft: draftWithoutDelay)

                if let date = draftWithoutDelay.scheduleDate, let changeFolderAction {
                    showScheduledSnackBar(
                        date: date,
                        scheduleAction: scheduleResponse.scheduleAction,
                        mailboxManager: mailboxManager,
                        changeFolderAction: changeFolderAction,
                        showSnackbar: showSnackbar
                    )
                }

                return nil
            }
        } catch let error as MailApiError where error == .sentLimitReached {
            await handleSentQuotaError(
                failingDraft: draft,
                mailboxManager: mailboxManager,
                showSnackbar: showSnackbar,
                kSuiteUpgradeAction: kSuiteUpgradeAction
            )
            throw ErrorDomain.sendQuota
        } catch let error as MailApiError where error == .apiIdentityNotFound {
            return try await handleIdentityNotFoundError(
                failingDraft: draft,
                mailboxManager: mailboxManager,
                retry: retry,
                showSnackbar: showSnackbar,
                changeFolderAction: changeFolderAction
            )
        } catch {
            alertDisplayable.show(message: error.localizedDescription, shouldShow: showSnackbar)
            throw ErrorDomain.cannotSendDraft
        }

        return nil
    }

    // TODO: - Delete local reaction and draft if necessary
    private func removeReactionIfNeeded(mailboxManager: MailboxManager, draft: Draft) {
        guard draft.action == .sendReaction, let reaction = draft.emojiReaction,
              let messageUid = draft.inReplyToUid else { return }

        try? mailboxManager.writeTransaction { writableRealm in
            guard let message = writableRealm.object(ofType: Message.self, forPrimaryKey: messageUid) else {
                return
            }

            guard let reactionIndex = message.reactions.firstIndex(where: { $0.reaction == reaction }) else { return }
            guard let index = message.reactions[reactionIndex].authors
                .firstIndex(where: { $0.recipient?.email == mailboxManager.mailbox.email })
            else { return }
            message.reactions[reactionIndex].authors.remove(at: index)
            if message.reactions[reactionIndex].authors.isEmpty {
                message.reactions.remove(at: reactionIndex)
            }
        }

        if let realm = draft.realm?.thaw(), let liveDraft = draft.fresh(using: realm) {
            try? realm.write {
                realm.delete(liveDraft)
            }
        }
    }

    private func handleSentQuotaError(failingDraft draft: Draft,
                                      mailboxManager: MailboxManager,
                                      showSnackbar: Bool,
                                      kSuiteUpgradeAction: ((LocalPack) -> Void)?) async {
        if let pack = mailboxManager.mailbox.pack,
           pack == .myKSuiteFree || pack == .kSuiteFree || pack == .starterPack {
            alertDisplayable.show(
                message: MailResourcesStrings.Localizable.errorSendLimitExceeded,
                action: (MailResourcesStrings.Localizable.buttonUpgrade, {
                    kSuiteUpgradeAction?(pack)
                })
            )
            matomo.track(eventWithCategory: .newMessage, name: "trySendingWithDailyLimitReached")
        } else {
            alertDisplayable.show(message: MailApiError.sentLimitReached.localizedDescription, shouldShow: showSnackbar)
        }

        await saveDraftAfterQuotaFail(draft: draft, mailboxManager: mailboxManager)
    }

    private func handleIdentityNotFoundError(failingDraft draft: Draft,
                                             mailboxManager: MailboxManager,
                                             retry: Bool,
                                             showSnackbar: Bool,
                                             changeFolderAction: ((Folder) -> Void)?) async throws -> Date? {
        // Refresh signatures and retry with default signature on missing identity
        guard retry else {
            alertDisplayable.show(message: MailApiError.apiIdentityNotFound.localizedDescription, shouldShow: showSnackbar)
            throw ErrorDomain.missingIdentity
        }

        try? await mailboxManager.refreshAllSignatures()
        guard let updatedDraft = await setDefaultSignature(draft: draft, mailboxManager: mailboxManager) else {
            throw ErrorDomain.missingIdentity
        }

        return try await sendOrSchedule(
            draft: updatedDraft,
            mailboxManager: mailboxManager,
            retry: false,
            showSnackbar: showSnackbar,
            changeFolderAction: changeFolderAction
        )
    }

    private func saveDraftAfterQuotaFail(draft: Draft, mailboxManager: MailboxManager) async {
        guard let liveDraft = draft.thaw() else { return }

        try? liveDraft.realm?.write {
            liveDraft.action = .initialSave
        }

        await saveDraftRemotely(
            draft: liveDraft.freeze(),
            mailboxManager: mailboxManager,
            retry: false,
            showSnackbar: false
        )
    }

    /// First save of a draft with the remote, if non empty.
    ///
    /// Present a message with a `delete draft`  action
    @discardableResult
    private func initialSaveRemotely(draft: Draft, mailboxManager: MailboxManager, showSnackbar: Bool) async -> Bool {
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

    private func showWillSendSnackbar(action: SaveDraftOption?, showSnackbar: Bool) {
        switch action {
        case .schedule:
            alertDisplayable.show(message: MailResourcesStrings.Localizable.snackbarScheduling, shouldShow: showSnackbar)
        case .send:
            alertDisplayable.show(message: MailResourcesStrings.Localizable.snackbarEmailSending, shouldShow: showSnackbar)
        default:
            break
        }
    }

    private func showDidSendSnackbar(
        draft: Draft,
        mailboxManager: MailboxManager,
        showSnackbar: Bool,
        action: UserAlertAction? = nil
    ) {
//        var action: UserAlertAction?
//        if let action {
//            action = UserAlertAction(MailResourcesStrings.Localizable.buttonCancel) {
//                Task {
//                    try await mailboxManager.apiFetcher.cancelSend(resource: cancelResource)
//                }
//            }
//        }
        switch draft.action {
        case .send:
            alertDisplayable.showWithDelay(
                message: MailResourcesStrings.Localizable.snackbarEmailSent,
                action: action,
                shouldShow: showSnackbar
            )
        case .sendReaction:
            guard showSnackbar, let reaction = draft.emojiReaction else { return }
            alertDisplayable
                .show(
                    message: MailResourcesStrings.Localizable.snackbarReactionSent(reaction),
                    action: action,
                    shouldShow: showSnackbar
                )
        default:
            break
        }
    }

    private func showScheduledSnackBar(
        date: Date,
        scheduleAction: String,
        mailboxManager: MailboxManager,
        changeFolderAction: @escaping (Folder) -> Void,
        showSnackbar: Bool
    ) {
        guard showSnackbar else { return }

        let formattedDate = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
        let changeFolderAlertAction = UserAlertAction(MailResourcesStrings.Localizable.draftFolder) {
            guard let draftFolder = mailboxManager.getFolder(with: .draft)?.freeze() else {
                mailboxManager.logError(.missingFolder)
                return
            }
            changeFolderAction(draftFolder)
        }
        let cancelButtonAlertAction = UserAlertAction(MailResourcesStrings.Localizable.buttonCancel) {
            Task {
                await tryOrDisplayError {
                    try await mailboxManager.moveScheduleToDraft(scheduleAction: scheduleAction)
                    self.alertDisplayable.show(
                        message: MailResourcesStrings.Localizable.snackbarSaveInDraft,
                        action: changeFolderAlertAction
                    )
                }
            }
        }

        alertDisplayable.show(
            message: MailResourcesStrings.Localizable.snackbarScheduleSaved(formattedDate),
            action: cancelButtonAlertAction
        )
    }

    private func removeDelay(draft: Draft) -> Draft {
        guard draft.delay != nil, let liveDraft = draft.thaw() else {
            return draft
        }

        try? liveDraft.realm?.write {
            liveDraft.delay = nil
        }
        return liveDraft.freeze()
    }
}
