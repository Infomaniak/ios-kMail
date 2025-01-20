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
import InfomaniakCoreCommonUI
import InfomaniakDI
import MailCore
import SwiftUI

@MainActor
enum DraftUtils {
    public static func editDraft(
        from thread: Thread,
        mailboxManager: MailboxManageable,
        composeMessageIntent: Binding<ComposeMessageIntent?>
    ) {
        guard let message = thread.messages.first else { return }

        DraftUtils.editDraft(from: message, mailboxManager: mailboxManager, composeMessageIntent: composeMessageIntent)
    }

    public static func editDraft(
        from message: Message,
        mailboxManager: MailboxManageable,
        composeMessageIntent: Binding<ComposeMessageIntent?>
    ) {
        // If we already have the draft locally, present it directly
        if let draft = mailboxManager.draft(messageUid: message.uid)?.detached() {
            matomoOpenDraft(isLoadedRemotely: false)
            composeMessageIntent.wrappedValue = ComposeMessageIntent.existing(draft: draft, originMailboxManager: mailboxManager)
            // Draft comes from API, we will update it after showing the ComposeMessageView
        } else {
            matomoOpenDraft(isLoadedRemotely: true)
            composeMessageIntent.wrappedValue = ComposeMessageIntent.existingRemote(
                messageUid: message.uid,
                originMailboxManager: mailboxManager
            )
        }
    }

    public static func editDraft(
        from draft: Draft,
        mailboxManager: MailboxManageable,
        composeMessageIntent: Binding<ComposeMessageIntent?>
    ) {
        let draftDetached = draft.detached()
        matomoOpenDraft(isLoadedRemotely: false)
        composeMessageIntent.wrappedValue = ComposeMessageIntent.existing(
            draft: draftDetached,
            originMailboxManager: mailboxManager
        )
    }

    private static func matomoOpenDraft(isLoadedRemotely: Bool) {
        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .newMessage, name: "openFromDraft")
        matomo.track(
            eventWithCategory: .newMessage,
            action: .data,
            name: "openLocalDraft",
            value: !isLoadedRemotely
        )
    }
}
