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

@available(iOS 18.4, *)
struct MailMessageOpenIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Message"

    @Parameter(title: "Message")
    var target: MailMessageEntity

    init() {}

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

        guard let tappedMessage = mailboxManager
            .fetchObject(ofType: Message.self, forPrimaryKey: target.id.messageId)?
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
