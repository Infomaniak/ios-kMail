/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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

import AppIntents
import Foundation
import InfomaniakDI
import MailCore

@available(iOS 27.0, *)
@AppIntent(schema: .mail.openDraft)
struct MailOpenDraft: OpenIntent {
    var target: MailDraftEntity

    func perform() async throws -> some IntentResult {
        @InjectService var accountManager: AccountManager
        @InjectService var mailboxInfosManager: MailboxInfosManager

        guard let mailbox = mailboxInfosManager.getMailbox(objectId: target.account.id),
              let mailboxManager = accountManager.getMailboxManager(for: mailbox) else {
            throw MailError.localMessageNotFound
        }

        MailAppIntentsHelper.switchAccountIfNeeded(
            mailbox: mailbox,
            mailboxManager: mailboxManager,
            accountManager: accountManager
        )

        guard let draft = try? MailAppIntentsHelper.resolveDraft(target, mailboxManager: mailboxManager).detached()
            .freezeIfNeeded() else {
            throw MailError.localMessageNotFound
        }

        @InjectService var mainViewStateStore: MainViewStateStore
        guard let initialFolder = mailboxManager.getFolder(with: .draft) ?? mailboxManager.getFolder(with: .inbox) else {
            throw MailError.localMessageNotFound
        }

        let intentMainViewState = await mainViewStateStore.getOrCreateMainViewState(
            for: mailboxManager,
            initialFolder: initialFolder
        )

        Task { @MainActor in
            intentMainViewState.composeMessageIntent = .existing(
                draft: draft,
                originMailboxManager: mailboxManager
            )
        }

        return .result()
    }
}

@available(iOS 27.0, *)
@AppIntent(schema: .mail.openMessage)
struct MailOpenMessage: OpenIntent {
    var target: MailMessageEntity

    func perform() async throws -> some IntentResult {
        @InjectService var accountManager: AccountManager
        @InjectService var mailboxInfosManager: MailboxInfosManager

        guard let mailbox = mailboxInfosManager.getMailbox(objectId: target.mailbox.id),
              let mailboxManager = accountManager.getMailboxManager(for: mailbox) else {
            throw MailError.localMessageNotFound
        }

        MailAppIntentsHelper.switchAccountIfNeeded(
            mailbox: mailbox,
            mailboxManager: mailboxManager,
            accountManager: accountManager
        )

        guard let tappedMessage = try? MailAppIntentsHelper.resolveMessage(target, mailboxManager: mailboxManager)
            .freezeIfNeeded(),
            let folder = tappedMessage.folder else {
            throw MailError.localMessageNotFound
        }

        @InjectService var mainViewStateStore: MainViewStateStore
        let intentMainViewState = await mainViewStateStore.getOrCreateMainViewState(
            for: mailboxManager,
            initialFolder: folder
        )

        guard let tappedThread = tappedMessage.originalThread else {
            throw MailError.localMessageNotFound
        }

        await MainActor.run {
            intentMainViewState.selectedThread = tappedThread
        }
        return .result()
    }
}
